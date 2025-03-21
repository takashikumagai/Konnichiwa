import os
import platform
import time
import psutil
import uvicorn
from datetime import datetime
from fastapi import FastAPI, HTTPException, Security
from fastapi.security import HTTPBearer
from dotenv import load_dotenv
from api.format_bytes import format_bytes

load_dotenv()

API_KEY = os.environ.get("API_KEY")

if not API_KEY:
    raise ValueError("API_KEY environment variable not set")

app = FastAPI()
security = HTTPBearer()


@app.get("/")
async def root():
    return {"message": "Konnichiwa"}


@app.get("/health")
async def health():
    return "ok"


@app.get("/inspect")
async def inspect(token: str = Security(security)):
    if token.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    process = psutil.Process(os.getpid())
    memory = psutil.virtual_memory()

    return {
        "now": datetime.now().isoformat(),
        "system": {
            "platform": platform.system(),
            "release": platform.release(),
            "arch": platform.machine(),
            "uptime": str(datetime.fromtimestamp(time.time() - psutil.boot_time())),
            "hostname": platform.node(),
            "cpu_used_percent": round(psutil.cpu_percent()),
            "memory_used_percent": round(psutil.virtual_memory().percent),
        },
        "memory": {
            "total": format_bytes(memory.total),
            "free": format_bytes(memory.available),
        },
        "process": {
            "pid": os.getpid(),
            "uptime": str(datetime.fromtimestamp(time.time() - process.create_time())),
            "memoryUsage": {
                "rss": format_bytes(process.memory_info().rss),
                "vms": format_bytes(process.memory_info().vms),
                "percent": f"{process.memory_percent():.2f}%",
            },
        },
    }


def bootstrap():
    try:
        uvicorn.run(app, host="0.0.0.0")
    except Exception as error:
        print(f"Error: {error}")
        exit(1)


if __name__ == "__main__":
    bootstrap()
