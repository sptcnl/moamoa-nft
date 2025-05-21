// 로그아웃 함수 (서버에 로그아웃 요청 후 홈으로 이동)
function logout() {
    fetch('/logout', {method: 'POST'}).then(() => {
        window.location.href = '/';
    });
}