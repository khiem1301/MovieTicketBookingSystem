(function () {
  'use strict';

  var toggleBtn = document.getElementById('togglePassword');
  var passwordInput = document.getElementById('password');

  if (toggleBtn && passwordInput) {
    toggleBtn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();

      var isHidden = passwordInput.type === 'password';
      passwordInput.type = isHidden ? 'text' : 'password';
      passwordInput.focus();

      var eye = toggleBtn.querySelector('.icon-eye');
      var eyeOff = toggleBtn.querySelector('.icon-eye-off');
      if (eye) eye.style.display = isHidden ? 'none' : '';
      if (eyeOff) eyeOff.style.display = isHidden ? '' : 'none';
    });
  }
})();
