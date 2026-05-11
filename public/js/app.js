
/* ================================================================
   FAVIO600RR SHOP — FUNCIONALIDAD v3
   ================================================================ */

(function () {
    "use strict";

    var CONFIG = {
        productName:    "Parlante Bluetooth TAXI",
        productPrice:   "203.40",
        promoPrice:     "180",
        productStock:   82,
        featuredInterval: 5000,
        whatsappNumber: "591700000000",
        sellerName:     "Favio600RR"
    };

    var GALLERY_IMAGES = ["assets/img/foto1.png","assets/img/foto2.png","assets/img/foto3.png","assets/img/foto4.png","assets/img/foto5.png","assets/img/foto6.png","assets/img/foto7.png","assets/img/foto8.png"];
    var VIDEOS         = [{ src: "assets/video/video1.mp4" }];
    var VARIANTS       = [{ id: "manillar", label: "Parlante para Manillar", qty: 0, max: 47 },{ id: "espejo", label: "Parlante para Espejo", qty: 0, max: 35 }];

    var currentIndex = 0;

    /* --- Init --- */
    document.addEventListener("DOMContentLoaded", function () {
        initImageFallback();
        initGallery();
        initVariants();
        initWhatsApp();
        initNav();
        initReveal();
        initVideos();
        initFeatured();
        initKeyboardNav();
        handleStock();
    });

    /* --- Image fallback --- */
    function initImageFallback() {
        var imgs = document.querySelectorAll("img");
        for (var i = 0; i < imgs.length; i++) {
            imgs[i].addEventListener("error", function () {
                this.style.opacity = "0.15";
                this.style.minHeight = "120px";
                this.style.background = "#181828";
            });
        }
    }

    /* --- Gallery --- */
    function initGallery() {
        var mainImg = document.getElementById("galleryMain");
        var thumbs  = document.querySelectorAll(".thumb");
        if (!mainImg || !thumbs.length) return;

        for (var i = 0; i < thumbs.length; i++) {
            thumbs[i].addEventListener("click", (function (idx) {
                return function () { changeImage(idx, mainImg, thumbs); };
            })(i));
        }
    }

    function changeImage(index, mainImg, thumbs) {
        if (index === currentIndex) return;
        mainImg.style.opacity = "0";
        currentIndex = index;

        for (var i = 0; i < thumbs.length; i++) {
            thumbs[i].classList.remove("active");
        }
        thumbs[index].classList.add("active");

        setTimeout(function () {
            mainImg.src = GALLERY_IMAGES[index];
            mainImg.style.opacity = "1";
        }, 280);
    }

    /* --- Variants (independent quantity selectors) --- */
    function initVariants() {
        var inputs = document.querySelectorAll(".variant-qty");
        for (var i = 0; i < inputs.length; i++) {
            (function (input) {
                var id = input.getAttribute("data-id");

                var minus = document.querySelector(".variant-minus[data-id=\"" + id + "\"]");
                var plus  = document.querySelector(".variant-plus[data-id=\"" + id + "\"]");

                function getVariantMax() {
                    for (var j = 0; j < VARIANTS.length; j++) {
                        if (VARIANTS[j].id === id) return VARIANTS[j].max;
                    }
                    return CONFIG.productStock;
                }

                function syncVariant() {
                    var v = parseInt(input.value, 10);
                    if (isNaN(v) || v < 0) v = 0;
                    var maxStock = getVariantMax();
                    if (v > maxStock) v = maxStock;
                    input.value = v;
                    for (var j = 0; j < VARIANTS.length; j++) {
                        if (VARIANTS[j].id === id) {
                            VARIANTS[j].qty = v;
                            break;
                        }
                    }
                    updateWhatsAppButton();
                }

                if (minus) {
                    minus.addEventListener("click", function () {
                        var v = parseInt(input.value, 10) || 0;
                        if (v > 0) { v--; input.value = v; syncVariant(); }
                    });
                }
                if (plus) {
                    plus.addEventListener("click", function () {
                        var v = parseInt(input.value, 10) || 0;
                        var maxStock = getVariantMax();
                        if (v < maxStock) { v++; input.value = v; syncVariant(); }
                    });
                }
                input.addEventListener("input", syncVariant);
            })(inputs[i]);
        }
    }

    function updateWhatsAppButton() {
        var btn = document.getElementById("whatsappBtn");
        if (!btn) return;
        var total = 0;
        for (var i = 0; i < VARIANTS.length; i++) {
            total += VARIANTS[i].qty;
        }
        if (total === 0) {
            btn.disabled = true;
            btn.innerHTML = "<span>💬</span> Selecciona al menos 1 producto";
        } else {
            btn.disabled = false;
            btn.innerHTML = "<span>💬</span> Pedir por WhatsApp";
        }
    }

    /* --- WhatsApp --- */
    function initWhatsApp() {
        var btn = document.getElementById("whatsappBtn");
        if (btn) btn.addEventListener("click", openWhatsApp);
    }

    function openWhatsApp() {
        var deptEl    = document.getElementById("department");
        var deptValue = deptEl ? deptEl.value : "";
        if (!deptValue) {
            alert("Por favor selecciona un departamento de entrega.");
            if (deptEl) deptEl.focus();
            return;
        }
        var lines = [];
        for (var i = 0; i < VARIANTS.length; i++) {
            if (VARIANTS[i].qty > 0) {
                lines.push("\u2022 " + VARIANTS[i].qty + "x " + VARIANTS[i].label);
            }
        }
        if (lines.length === 0) return;
        var msg = "Hola " + CONFIG.sellerName + ", quiero:\n" +
            lines.join("\n") +
            "\npara el departamento de " + deptValue;
        var url = "https://wa.me/" + CONFIG.whatsappNumber +
            "?text=" + encodeURIComponent(msg);
        window.open(url, "_blank");
    }

    /* --- Mobile nav --- */
    function initNav() {
        var toggle = document.getElementById("navToggle");
        var nav    = document.getElementById("nav");
        if (!toggle || !nav) return;

        toggle.addEventListener("click", function () {
            nav.classList.toggle("open");
            toggle.classList.toggle("active");
        });

        var links = nav.querySelectorAll(".nav-link");
        for (var i = 0; i < links.length; i++) {
            links[i].addEventListener("click", function () {
                nav.classList.remove("open");
                toggle.classList.remove("active");
            });
        }

        document.addEventListener("click", function (e) {
            if (!nav.contains(e.target) && !toggle.contains(e.target)) {
                nav.classList.remove("open");
                toggle.classList.remove("active");
            }
        });
    }

    /* --- Scroll reveal --- */
    function initReveal() {
        var sections = document.querySelectorAll(".section");
        for (var i = 0; i < sections.length; i++) {
            sections[i].classList.add("reveal");
        }
        if (!("IntersectionObserver" in window)) {
            for (var j = 0; j < sections.length; j++) {
                sections[j].classList.add("active");
            }
            return;
        }
        var obs = new IntersectionObserver(function (entries) {
            for (var k = 0; k < entries.length; k++) {
                if (entries[k].isIntersecting) {
                    entries[k].target.classList.add("active");
                }
            }
        }, { threshold: 0.08 });
        for (var l = 0; l < sections.length; l++) {
            obs.observe(sections[l]);
        }
    }

    /* --- Video orientation detection --- */
    function initVideos() {
        var videos = document.querySelectorAll(".video-wrapper video");
        for (var i = 0; i < videos.length; i++) {
            videos[i].addEventListener("loadedmetadata", function () {
                if (this.videoWidth && this.videoHeight &&
                    this.videoWidth < this.videoHeight) {
                    this.classList.add("portrait");
                }
            });
        }
    }

    /* --- Featured product rotation --- */
    function initFeatured() {
        var container = document.getElementById("productFeatured");
        if (!container) return;
        var slides = container.querySelectorAll(".featured-slide");
        var dots   = container.querySelectorAll(".dot");
        if (slides.length < 2) {
            if (dots.length) {
                for (var d = 0; d < dots.length; d++) dots[d].style.display = "none";
            }
            return;
        }
        var current = 0;

        function goTo(index) {
            if (index === current) return;
            slides[current].classList.remove("active");
            if (dots.length) dots[current].classList.remove("active");
            current = index;
            slides[current].classList.add("active");
            if (dots.length) dots[current].classList.add("active");
        }

        if (dots.length) {
            for (var i = 0; i < dots.length; i++) {
                (function (idx) {
                    dots[idx].addEventListener("click", function () { goTo(idx); });
                })(i);
            }
        }

        setInterval(function () {
            var next = (current + 1) % slides.length;
            goTo(next);
        }, CONFIG.featuredInterval);
    }

    /* --- Keyboard navigation (arrow up/down between sections) --- */
    function initKeyboardNav() {
        var locked = false;
        var sections = [];
        var all = document.querySelectorAll("section[id]");
        for (var i = 0; i < all.length; i++) sections.push(all[i]);

        function shouldIgnore(el) {
            var tag = el.tagName.toLowerCase();
            return tag === "input" || tag === "textarea" || tag === "select" || el.isContentEditable;
        }

        document.addEventListener("keydown", function (e) {
            if (locked) return;
            var key = e.key;
            if (key !== "ArrowDown" && key !== "ArrowUp" && key !== "PageDown" && key !== "PageUp") return;
            if (shouldIgnore(e.target)) return;
            e.preventDefault();

            var closest = null;
            var closestDist = Infinity;
            var viewCenter = window.scrollY + window.innerHeight / 2;

            for (var i = 0; i < sections.length; i++) {
                var rect = sections[i].getBoundingClientRect();
                var secCenter = rect.top + rect.height / 2;
                var dist = Math.abs(secCenter);
                if (dist < closestDist) {
                    closestDist = dist;
                    closest = i;
                }
            }

            if (closest === null) return;
            var target = -1;

            if (key === "ArrowDown" || key === "PageDown") {
                target = closest + 1;
                if (target >= sections.length) return;
            } else {
                target = closest - 1;
                if (target < 0) return;
            }

            locked = true;
            sections[target].scrollIntoView({ behavior: "smooth", block: "start" });
            setTimeout(function () { locked = false; }, 800);
        });
    }

    /* --- Stock --- */
    function handleStock() {
        var hasStock = false;
        for (var i = 0; i < VARIANTS.length; i++) {
            if (VARIANTS[i].max > 0) { hasStock = true; break; }
        }
        if (hasStock) return;

        var badge = document.getElementById("stockBadge");
        if (badge) {
            badge.textContent       = "Agotado";
            badge.style.background  = "rgba(255, 50, 50, 0.12)";
            badge.style.color       = "#ff5050";
            badge.style.borderColor = "rgba(255, 50, 50, 0.2)";
        }
        var btn = document.getElementById("whatsappBtn");
        if (btn) { btn.disabled = true; btn.textContent = "Producto agotado"; }
        var btns = document.querySelectorAll(".variant-minus, .variant-plus");
        for (var i = 0; i < btns.length; i++) btns[i].disabled = true;
    }

})();
