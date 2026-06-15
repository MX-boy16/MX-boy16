from fastapi import FastAPI, APIRouter
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List
import uuid
from datetime import datetime, timezone


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Resource folder (FiveM resource lives at /app/dusa_mechanic_qbx)
RESOURCE_DIR = Path('/app/dusa_mechanic_qbx')
ZIP_PATH = Path('/app/dusa_mechanic_qbx.zip')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

app = FastAPI()
api_router = APIRouter(prefix="/api")


class StatusCheck(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class StatusCheckCreate(BaseModel):
    client_name: str


@api_router.get("/")
async def root():
    return {"message": "Dusa Mechanic QBX API"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.model_dump()
    status_obj = StatusCheck(**status_dict)
    doc = status_obj.model_dump()
    doc['timestamp'] = doc['timestamp'].isoformat()
    _ = await db.status_checks.insert_one(doc)
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    status_checks = await db.status_checks.find({}, {"_id": 0}).to_list(1000)
    for check in status_checks:
        if isinstance(check['timestamp'], str):
            check['timestamp'] = datetime.fromisoformat(check['timestamp'])
    return status_checks


# ============================================================
# Resource browser endpoints
# ============================================================
@api_router.get("/resource/manifest")
async def resource_manifest():
    """List all files of the FiveM resource with sizes for the landing page."""
    if not RESOURCE_DIR.exists():
        return {"files": [], "total_size": 0}
    files = []
    total = 0
    for p in sorted(RESOURCE_DIR.rglob('*')):
        if p.is_file():
            rel = p.relative_to(RESOURCE_DIR).as_posix()
            size = p.stat().st_size
            total += size
            files.append({"path": rel, "size": size})
    return {"files": files, "total_size": total, "file_count": len(files)}


@api_router.get("/resource/file")
async def resource_file(path: str):
    """Serve raw content of a single file from the resource (for in-browser viewing)."""
    target = (RESOURCE_DIR / path).resolve()
    if not str(target).startswith(str(RESOURCE_DIR.resolve())):
        return {"error": "forbidden"}
    if not target.is_file():
        return {"error": "not found"}
    return FileResponse(target, media_type='text/plain')


@api_router.get("/resource/download")
async def resource_download():
    """Download the entire resource as a zip."""
    if not ZIP_PATH.exists():
        # Re-zip on the fly
        import zipfile
        with zipfile.ZipFile(ZIP_PATH, 'w', zipfile.ZIP_DEFLATED) as z:
            for p in RESOURCE_DIR.rglob('*'):
                if p.is_file():
                    z.write(p, p.relative_to(RESOURCE_DIR.parent))
    return FileResponse(ZIP_PATH, media_type='application/zip',
                        filename='dusa_mechanic_qbx.zip')


app.include_router(api_router)

# Mount NUI preview as static at /api/preview/* (so the kubernetes ingress
# routes it to the backend pod)
if (RESOURCE_DIR / 'html').exists():
    app.mount("/api/preview", StaticFiles(directory=str(RESOURCE_DIR / 'html'), html=True),
              name="preview")

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
