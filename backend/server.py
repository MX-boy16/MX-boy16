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

# Resources available for download (extensible)
RESOURCES = {
    'dusa_mechanic_qbx': {
        'label': 'Dusa Mechanic (shops, lifts, society)',
        'dir': Path('/app/dusa_mechanic_qbx'),
        'zip': Path('/app/dusa_mechanic_qbx.zip'),
        'preview_path': '/api/preview/dusa_mechanic_qbx/index.html',
    },
    'mechanic_tablet': {
        'label': 'Mechanic Tablet (in-vehicle, job-gated)',
        'dir': Path('/app/mechanic_tablet'),
        'zip': Path('/app/mechanic_tablet.zip'),
        'preview_path': '/api/preview/mechanic_tablet/index.html',
    },
}

# Legacy single-resource constants (kept for backwards compat with old endpoints)
RESOURCE_DIR = RESOURCES['dusa_mechanic_qbx']['dir']
ZIP_PATH = RESOURCES['dusa_mechanic_qbx']['zip']

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
# Resource browser endpoints (multi-resource)
# ============================================================
def _zip_resource(res_key: str) -> Path:
    info = RESOURCES[res_key]
    if not info['zip'].exists() or info['zip'].stat().st_mtime < max(
        (p.stat().st_mtime for p in info['dir'].rglob('*') if p.is_file()), default=0
    ):
        import zipfile
        with zipfile.ZipFile(info['zip'], 'w', zipfile.ZIP_DEFLATED) as z:
            for p in info['dir'].rglob('*'):
                if p.is_file():
                    z.write(p, Path(res_key) / p.relative_to(info['dir']))
    return info['zip']


@api_router.get("/resources")
async def list_resources():
    out = []
    for key, info in RESOURCES.items():
        files = list(info['dir'].rglob('*')) if info['dir'].exists() else []
        files = [p for p in files if p.is_file()]
        total = sum(p.stat().st_size for p in files)
        out.append({
            'key': key,
            'label': info['label'],
            'file_count': len(files),
            'total_size': total,
            'preview_path': info['preview_path'],
            'download_path': f'/api/resources/{key}/download',
        })
    return out


@api_router.get("/resources/{res_key}/manifest")
async def resource_manifest_v2(res_key: str):
    if res_key not in RESOURCES:
        return {"error": "not found"}
    info = RESOURCES[res_key]
    files, total = [], 0
    if info['dir'].exists():
        for p in sorted(info['dir'].rglob('*')):
            if p.is_file():
                size = p.stat().st_size
                total += size
                files.append({"path": p.relative_to(info['dir']).as_posix(), "size": size})
    return {"files": files, "total_size": total, "file_count": len(files)}


@api_router.get("/resources/{res_key}/download")
async def resource_download_v2(res_key: str):
    if res_key not in RESOURCES:
        return {"error": "not found"}
    z = _zip_resource(res_key)
    return FileResponse(z, media_type='application/zip', filename=f'{res_key}.zip')


# ============================================================
# Legacy single-resource endpoints (backwards compat)
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
    """Download the entire (legacy) resource as a zip."""
    z = _zip_resource('dusa_mechanic_qbx')
    return FileResponse(z, media_type='application/zip', filename='dusa_mechanic_qbx.zip')


app.include_router(api_router)

# Mount each resource's NUI preview as static at /api/preview/{key}/*
for _key, _info in RESOURCES.items():
    _html_dir = _info['dir'] / 'html'
    if _html_dir.exists():
        app.mount(f"/api/preview/{_key}", StaticFiles(directory=str(_html_dir), html=True),
                  name=f"preview_{_key}")

# Backwards-compat legacy mount (old landing referenced /api/preview/index.html)
_legacy_html = Path('/app/dusa_mechanic_qbx/html')
if _legacy_html.exists():
    app.mount("/api/preview", StaticFiles(directory=str(_legacy_html), html=True),
              name="preview_legacy")

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
