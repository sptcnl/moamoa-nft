# FastAPI와 필요한 모듈을 임포트합니다.
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, Response
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
import os
from dotenv import load_dotenv
import json
from fastapi.staticfiles import StaticFiles

# .env 파일을 다시 읽어서 환경변수 갱신
load_dotenv(override=True)
FAM_CONTRACT_ADDRESS = os.getenv("FAM_CONTRACT_ADDRESS")
NFT_CONTRACT_ADDRESS = os.getenv("NFT_CONTRACT_ADDRESS")
print("가족 컨트랙트 주소: ", FAM_CONTRACT_ADDRESS)
print("NFT 컨트랙트 주소: ", NFT_CONTRACT_ADDRESS)

# FastAPI 앱을 생성할 때 docs와 redoc을 비활성화합니다.
app = FastAPI(docs_url=None, redoc_url=None)

# 세션 미들웨어 추가 (임의의 시크릿키 사용)
app.add_middleware(SessionMiddleware, secret_key="moamoa-kids")

# 정적 파일 설정
app.mount("/static", StaticFiles(directory="static"), name="static")

# Jinja2 템플릿 디렉토리를 지정합니다.
templates = Jinja2Templates(directory="templates")

# ABI 파일 로드 (없으면 빈 리스트)
try:
    with open("static/moamoakids_abi.json") as f:
        contract_abi = json.load(f)
except Exception:
    contract_abi = []
    print("가족 컨트랙트 ABI 로드 실패")

# NFT 컨트랙트 ABI 로드
try:
    with open("static/moa_nft_abi.json") as f:
        nft_abi = json.load(f)
    print("NFT 컨트랙트 ABI 로드 성공")
except Exception:
    nft_abi = []
    print("NFT 컨트랙트 ABI 로드 실패")

# 루트 - 로그인 여부에 따라 main.html 또는 family.html 렌더링
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    # 세션에서 로그인 여부 확인
    if request.session.get("wallet_login"):
        # 로그인 완료 시 가족 관리 페이지 렌더링
        return templates.TemplateResponse("family.html", {"request": request, "contract_address": FAM_CONTRACT_ADDRESS, "contract_abi": contract_abi})
    # 로그인 전이면 메인 페이지 렌더링
    return templates.TemplateResponse("main.html", {"request": request})

# 가족 관리 페이지 - family.html 렌더링
@app.get("/family", response_class=HTMLResponse)
async def family_page(request: Request):
    is_logged_in = bool(request.session.get("wallet_login"))
    return templates.TemplateResponse("family.html", {"request": request, "contract_address": FAM_CONTRACT_ADDRESS, "contract_abi": contract_abi, "is_logged_in": is_logged_in})

# NFT 페이지 - nft.html 렌더링
@app.get("/nft", response_class=HTMLResponse)
async def nft_page(request: Request):
    is_logged_in = bool(request.session.get("wallet_login"))
    return templates.TemplateResponse("nft.html", {"request": request, "contract_address": NFT_CONTRACT_ADDRESS, "contract_abi": nft_abi, "is_logged_in": is_logged_in})

# 지갑 로그인 성공 시 세션에 wallet_login 값을 true로 저장하는
@app.post("/wallet-login")
async def wallet_login(request: Request):
    request.session["wallet_login"] = True
    return Response(status_code=204)

# 로그아웃
@app.post("/logout")
async def logout(request: Request):
    request.session.clear()
    return Response(status_code=204) 