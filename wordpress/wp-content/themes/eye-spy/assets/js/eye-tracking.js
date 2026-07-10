(function () {
    "use strict";

    function initEyeTracking() {
        var eyes = document.querySelectorAll(".eye");
        if (!eyes.length) {
            return;
        }

        var entries = Array.prototype.map.call(eyes, function (eye) {
            return { eye: eye, pupil: eye.querySelector(".eye__pupil") };
        }).filter(function (entry) {
            return entry.pupil;
        });

        function updatePupils(pointerX, pointerY) {
            entries.forEach(function (entry) {
                var eyeRect = entry.eye.getBoundingClientRect();
                var pupilRect = entry.pupil.getBoundingClientRect();
                var centerX = eyeRect.left + eyeRect.width / 2;
                var centerY = eyeRect.top + eyeRect.height / 2;
                var dx = pointerX - centerX;
                var dy = pointerY - centerY;
                var angle = Math.atan2(dy, dx);
                var maxOffset = eyeRect.width / 2 - pupilRect.width / 2;
                var distance = Math.min(Math.hypot(dx, dy), maxOffset);
                var offsetX = Math.cos(angle) * distance;
                var offsetY = Math.sin(angle) * distance;
                entry.pupil.style.transform =
                    "translate(" + offsetX.toFixed(1) + "px, " + offsetY.toFixed(1) + "px)";
            });
        }

        window.addEventListener("mousemove", function (event) {
            updatePupils(event.clientX, event.clientY);
        });

        window.addEventListener(
            "touchmove",
            function (event) {
                var touch = event.touches[0];
                if (touch) {
                    updatePupils(touch.clientX, touch.clientY);
                }
            },
            { passive: true }
        );
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initEyeTracking);
    } else {
        initEyeTracking();
    }
})();
