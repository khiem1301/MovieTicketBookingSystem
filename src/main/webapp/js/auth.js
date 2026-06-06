document.addEventListener("DOMContentLoaded", function () {
    var toggleButtons = document.querySelectorAll("[data-toggle-password]");

    toggleButtons.forEach(function (button) {
        button.addEventListener("click", function () {
            var input = button.closest(".auth-input-wrap").querySelector(".auth-input--password");
            if (!input) {
                return;
            }

            var isPassword = input.type === "password";
            input.type = isPassword ? "text" : "password";
            button.classList.toggle("is-visible", isPassword);
            button.setAttribute("aria-label", isPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu");
        });
    });
});
