# ⚡ Favio600rr Shop — Landing Page

Landing page profesional y estática para vender parlantes Bluetooth para motos. Generada con Bash puro, diseñada para **GitHub Pages** con despliegue automatizado mediante **GitHub Actions**.

---

## ✨ Características

- Diseño **premium oscuro** con acentos vibrantes
- **Responsive**: escritorio, tablet y móvil
- Galería interactiva con miniaturas
- Reproductor de video HTML5
- Pedidos por **WhatsApp** con mensaje dinámico
- Selector de cantidad y departamento (Bolivia)
- Animaciones suaves con IntersectionObserver
- SEO básico y Open Graph
- Sin frameworks, sin backend, sin Node.js
- Generación estática tipo **Hugo-style**

---

## 🚀 Inicio rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/favio600rr/favio600rr.git
cd favio600rr

# 2. Generar el sitio
chmod +x generar.sh
./generar.sh

# 3. Abrir en el navegador
open public/index.html
```

---

## 📁 Estructura del proyecto

```
/
├── .github/
│   └── workflows/
│       └── deploy.yml        ← CI/CD: despliegue automático
├── public/                   ← Sitio generado (salida)
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── app.js
│   └── assets/
│       ├── img/
│       │   ├── foto1.png
│       │   ├── foto2.png
│       │   ├── foto3.png
│       │   ├── foto4.png
│       │   └── foto5.png
│       └── video/
│           └── video1.mp4
├── generar.sh                ← Generador del sitio
├── README.md
└── .gitignore
```

---

## 🛠️ Personalización

Edita las variables al inicio de `generar.sh`:

```bash
SITE_TITLE="Favio600rr Shop"
SITE_DESCRIPTION="Parlantes Bluetooth premium para motos..."
PRODUCT_NAME="Parlante Bluetooth FX600 Pro"
PRODUCT_PRICE="249.99"
PRODUCT_STOCK="25"
WHATSAPP_NUMBER="59170000000"
SELLER_NAME="Favio600rr"
PRIMARY_COLOR="#ff6b35"
SECONDARY_COLOR="#00d4ff"
```

Luego regenera el sitio:

```bash
./generar.sh
```

---

## 🌐 Publicar en GitHub Pages

### 1. Subir el repositorio

```bash
git remote add origin https://github.com/favio600rr/favio600rr.git
git push -u origin main
```

### 2. Configurar GitHub Pages

1. Ve a **Settings > Pages** de tu repositorio
2. En **Source**, selecciona **Deploy from a branch**
3. Branch: `master` / `/(root)`
4. Guardar

### 3. Resultado

Tu sitio estará disponible en:
```
https://favio600rr.github.io/
```

Cada vez que hagas `push` a `main`, el workflow de GitHub Actions:

1. Ejecuta `generar.sh` → genera todo dentro de `/public`
2. Despliega el contenido de `/public` a la rama `master`
3. GitHub Pages sirve la rama `master`

---

## 🔄 Flujo de trabajo (CI/CD)

| Evento | Acción |
|--------|--------|
| `push` a `main` | Se ejecuta el workflow `.github/workflows/deploy.yml` |
| El workflow | Corre `generar.sh` y genera el sitio en `/public` |
| `peaceiris/actions-gh-pages` | Despliega `/public` a la rama `master` |
| GitHub Pages | Sirve la rama `master` automáticamente |

No se necesita configuración manual después del primer setup.

---

## 📦 Reemplazar contenido real

Antes de publicar, reemplaza los placeholders:

| Archivo | Reemplazar con |
|---------|----------------|
| `public/assets/img/foto1.png` | Foto principal del producto |
| `public/assets/img/foto2.png` | Ángulo lateral |
| `public/assets/img/foto3.png` | Detalle / acercamiento |
| `public/assets/img/foto4.png` | Instalación en moto |
| `public/assets/img/foto5.png` | Producto en uso |
| `public/assets/video/video1.mp4` | Video promocional |

---

## 🧪 Requisitos

- **Bash** 4.0+
- **Python 3** (opcional, para generar imágenes placeholder)
- Navegador web moderno (Chrome, Firefox, Edge)

---

## 📄 Licencia

Este proyecto es de uso libre.
