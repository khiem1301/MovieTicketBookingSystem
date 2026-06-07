(function () {
  'use strict';

  function bindToggle(btn) {
    var targetId = btn.getAttribute('data-target') || 'password';
    var input = document.getElementById(targetId);
    if (!input) return;

    btn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();

      var isHidden = input.type === 'password';
      input.type = isHidden ? 'text' : 'password';
      input.focus();

      var eye = btn.querySelector('.icon-eye');
      var eyeOff = btn.querySelector('.icon-eye-off');
      if (eye) eye.style.display = isHidden ? 'none' : '';
      if (eyeOff) eyeOff.style.display = isHidden ? '' : 'none';
    });
  }

  document.querySelectorAll('.auth-toggle-pw').forEach(bindToggle);
})();
