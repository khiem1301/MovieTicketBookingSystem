(function () {
  var input = document.getElementById('avatar');
  var preview = document.getElementById('profile-avatar-preview');
  if (!input || !preview) return;

  input.addEventListener('change', function () {
    var file = input.files && input.files[0];
    if (!file) return;
    if (!file.type.match(/^image\/(jpeg|jpg|png)$/i)) return;

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
