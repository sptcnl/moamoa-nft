// 세션에 로그인 완료 표시를 남기는 함수
async function setWalletLoginAndRedirect(address) {
    await fetch('/wallet-login', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ address })
    });
    window.location.href = '/';
}

// Kaikas 로그인 함수 예시
async function connectKaikas() {
    if (window.klaytn) {
        try {
            const accounts = await window.klaytn.enable();
            if (accounts && accounts[0]) {
                await setWalletLoginAndRedirect(accounts[0]);
            }
        } catch (error) {
            alert('Kaikas 연결 실패: ' + error.message);
        }
    } else {
        alert('Kaikas가 설치되어 있지 않습니다.');
    }
}

  // 페이지가 처음 열릴 때 실행되는 함수
  window.onload = async function() {
    // 1. 브라우저에 이더리움 지갑(메타마스크 등)이 설치되어 있는지 확인
    if (window.ethereum) {
        await connectWallet(); // 있으면 지갑 연결 시도
    } else {
        // 없으면 에러 메시지 표시
        document.getElementById('message').innerHTML = '<span class="error">지갑이 연결되어 있지 않습니다.</span>';
    }
};
 