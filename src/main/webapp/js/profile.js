(function () {
  var input = document.getElementById('avatar');
  var preview = document.getElementById('profile-avatar-preview');
  var wrap = document.getElementById('profile-avatar-wrap');
  var errorBox = document.getElementById('profile-avatar-error');
  if (!input || !preview || !wrap) return;

  var MAX_BYTES = 1024 * 1024;
  var msgType = wrap.dataset.msgType || '';
  var msgSize = wrap.dataset.msgSize || '';

  function showError(message) {
    if (!errorBox || !message) return;
    errorBox.textContent = message;
    errorBox.hidden = false;
  }

  function clearError() {
    if (!errorBox) return;
    errorBox.textContent = '';
    errorBox.hidden = true;
  }

  input.addEventListener('change', function () {
    var file = input.files && input.files[0];
    if (!file) {
      clearError();
      return;
    }

    if (!file.type.match(/^image\/(jpeg|jpg|png)$/i)) {
      showError(msgType);
      input.value = '';
      return;
    }

    if (file.size > MAX_BYTES) {
      showError(msgSize);
      input.value = '';
      return;
    }

    clearError();

    var reader = new FileReader();
    reader.onload = function (e) {
      if (preview.tagName === 'IMG') {
        preview.src = e.target.result;
      } else {
        var img = document.createElement('img');
        img.id = 'profile-avatar-preview';
        img.className = 'profile-avatar-lg';
        img.alt = 'Avatar preview';
        img.src = e.target.result;
        preview.replaceWith(img);
      }
    };
    reader.readAsDataURL(file);
  });
})();
