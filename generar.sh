#!/usr/bin/env bash
#
# =============================================================================
#  GENERADOR DE LANDING PAGE — Favio600rr
#  Detecta assets dinámicamente y genera sitio estático en /public
#  Compatible con GitHub Pages + CI/CD
# =============================================================================
#  Uso:  chmod +x generar.sh && ./generar.sh
#        Coloca tus imágenes en assets/img/ y videos en assets/video/
# =============================================================================

set -Eeuo pipefail

# =============================================================================
#  CONFIGURACIÓN — Edita estas variables
# =============================================================================
SITE_TITLE="Favio600RR Shop"
SITE_DESCRIPTION="Parlantes Bluetooth para motos. Potencia, estilo y sonido sobre ruedas."
PRODUCT_NAME="Parlante Bluetooth TAXI"
PRODUCT_PRICE="203.40"
PROMO_PRICE="180"                      # vacío = sin promo, ej: "150" = precio promocional
PRODUCT_STOCK="77"                     # stock total (suma de variantes)
WHATSAPP_NUMBER="59178037726"
SECONDARY_WHATSAPP_NUMBER="78037726"        # vacío = ocultar bloque alternativo
ENABLE_SECONDARY_WHATSAPP_LINK="false"       # "true" = enlace wa.me, "false" = solo texto
SELLER_NAME="Favio600RR"
PRIMARY_COLOR="#ff6b35"
SECONDARY_COLOR="#00d4ff"

HERO_FEATURES=(
    "🎵 Sonido HD"
    "📱 Bluetooth"
    "💧 Resistente al agua"
    "🔋 Cargador vía USB"
)

# Stock individual por variante
STOCK_MANILLAR="31"
STOCK_ESPEJO="19"

PRODUCT_VARIANTS=(
    "Parlante para Manillar|manillar"
    "Parlante para Espejo|espejo"
)

# Imágenes destacadas del producto — nombre de archivo en assets/img/
FEATURED_PRODUCT_1="foto4.png"
FEATURED_PRODUCT_1_LABEL="Parlante para Manillar"
FEATURED_PRODUCT_2="foto9.png"
FEATURED_PRODUCT_2_LABEL="Parlante para Espejo"
FEATURED_ROTATION_INTERVAL="5000"

# Redes sociales — deja vacío para ocultar
INSTAGRAM_URL=""
TIKTOK_URL=""
YOUTUBE_URL=""
FACEBOOK_URL=""
TWITTER_URL=""
X_URL=""
TELEGRAM_URL=""
WHATSAPP_CHANNEL_URL=""
DISCORD_URL=""
TWITCH_URL=""
THREADS_URL=""
LINKEDIN_URL=""
GITHUB_URL=""

# =============================================================================
#  NO EDITES DEBAJO DE ESTA LÍNEA
# =============================================================================

# Resolver stock por variante (fallback a PRODUCT_STOCK si están vacíos)
: "${STOCK_MANILLAR:=$PRODUCT_STOCK}"
: "${STOCK_ESPEJO:=$PRODUCT_STOCK}"
TOTAL_STOCK=$((STOCK_MANILLAR + STOCK_ESPEJO))

readonly OUTPUT_DIR="public"
readonly SCRIPT_VERSION="3.0.0"

# Arrays globales (poblados por detect_assets)
declare -a DETECTED_IMAGES=()
declare -a DETECTED_VIDEOS=()

# Colores para mensajes
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'
readonly C_CYAN='\033[0;36m'
readonly C_BOLD='\033[1m'
readonly C_RESET='\033[0m'

PYTHON_CMD=""

# =============================================================================
#  FUNCIONES AUXILIARES
# =============================================================================
log_info()  { echo -e "  ${C_GREEN}✓${C_RESET} $1"; }
log_warn()  { echo -e "  ${C_YELLOW}⚠${C_RESET} $1"; }
log_error() { echo -e "  ${C_RED}✗${C_RESET} $1"; }
log_step()  { echo -e "\n  ${C_CYAN}▸${C_RESET} ${C_BOLD}$1${C_RESET}"; }

error_handler() {
    local line=$1
    local cmd=$2
    echo -e "\n  ${C_RED}Error en línea ${line}: '${cmd}'${C_RESET}" >&2
    exit 1
}
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

cleanup() { :; }
trap cleanup EXIT INT TERM

# =============================================================================
#  VERIFICAR DEPENDENCIAS
# =============================================================================
verify_dependencies() {
    log_step "Verificando dependencias"

    local missing=0
    for cmd in mkdir rm cat sed printf cp find sort touch; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Comando requerido no encontrado: ${cmd}"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "\n  ${C_RED}Error: Faltan dependencias esenciales.${C_RESET}" >&2
        exit 1
    fi
    log_info "Dependencias básicas OK"

    PYTHON_CMD=""
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        log_info "Python3 disponible para imágenes placeholder"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        log_info "Python disponible para imágenes placeholder"
    else
        log_warn "Python no disponible. Las imágenes placeholder serán archivos vacíos."
    fi
}

# =============================================================================
#  LIMPIAR BUILD ANTERIOR
# =============================================================================
clean_previous_build() {
    log_step "Limpiando build anterior"
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "${OUTPUT_DIR:?}/"
        log_info "Directorio ${OUTPUT_DIR} limpiado"
    else
        log_info "No hay build previo que limpiar"
    fi
}

# =============================================================================
#  CREAR DIRECTORIOS
# =============================================================================
create_directories() {
    log_step "Creando estructura de directorios"
    mkdir -p "${OUTPUT_DIR}/css" \
             "${OUTPUT_DIR}/js" \
             "${OUTPUT_DIR}/assets/img" \
             "${OUTPUT_DIR}/assets/video" \
             "assets/img" \
             "assets/video" \
             ".github/workflows"
    log_info "Estructura creada en ${OUTPUT_DIR}/"
}

# =============================================================================
#  GENERAR IMÁGENES PLACEHOLDER VÍA PYTHON
# =============================================================================
generate_placeholder_images() {
    local dst="$1"
    if [ -z "$PYTHON_CMD" ]; then
        log_warn "Generando 5 imágenes placeholder vacías"
        for i in 1 2 3 4 5; do
            touch "${dst}/foto${i}.png"
        done
        return
    fi

    $PYTHON_CMD << PYEOF
import struct, zlib, os

def create_png(filepath, width, height, r, g, b):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    signature = b'\x89PNG\r\n\x1a\n'

    def make_chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc

    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)
        for x in range(width):
            raw_data.extend([r, g, b])
    compressed = zlib.compress(bytes(raw_data))
    idat = make_chunk(b'IDAT', compressed)
    iend = make_chunk(b'IEND', b'')
    with open(filepath, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

output_dir = "${dst}"
colors = [
    (255, 107, 53),
    (0, 212, 255),
    (180, 50, 255),
    (50, 220, 100),
    (255, 200, 50),
]
for i, (r, g, b) in enumerate(colors, 1):
    filepath = os.path.join(output_dir, 'foto{}.png'.format(i))
    create_png(filepath, 600, 400, r, g, b)
    print('    Creado: ' + filepath)
PYEOF
}

# =============================================================================
#  GENERAR VIDEO PLACEHOLDER
# =============================================================================
generate_placeholder_video() {
    local dst="$1"
    touch "${dst}/video1.mp4"
    log_info "Placeholder de video creado en ${dst}/video1.mp4"
}

# =============================================================================
#  DETECTAR ASSETS
# =============================================================================
detect_assets() {
    log_step "Detectando assets"

    local src_img="assets/img"
    local src_vid="assets/video"
    local dst_img="${OUTPUT_DIR}/assets/img"
    local dst_vid="${OUTPUT_DIR}/assets/video"

    # ─── Imágenes ───
    mkdir -p "$src_img" "$dst_img"
    DETECTED_IMAGES=()

    while IFS= read -r -d '' f; do
        DETECTED_IMAGES+=("$f")
    done < <(find "$src_img" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0 2>/dev/null | sort -z)

    if [ ${#DETECTED_IMAGES[@]} -gt 0 ]; then
        log_info "Copiando ${#DETECTED_IMAGES[@]} imagen(es) desde ${src_img}/"
        for f in "${DETECTED_IMAGES[@]}"; do
            cp "$f" "$dst_img/"
        done
    else
        log_warn "No se encontraron imágenes reales en ${src_img}/. Generando placeholders..."
        generate_placeholder_images "$dst_img"
    fi

    # Re-poblar con archivos finales en dst
    DETECTED_IMAGES=()
    while IFS= read -r -d '' f; do
        DETECTED_IMAGES+=("$f")
    done < <(find "$dst_img" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)

    local img_count=${#DETECTED_IMAGES[@]}
    log_info "${img_count} imagen(es) disponible(s)"

    if [ $img_count -eq 0 ]; then
        log_error "No hay imágenes disponibles. Abortando."
        exit 1
    fi

    # ─── Videos ───
    mkdir -p "$src_vid" "$dst_vid"
    DETECTED_VIDEOS=()

    while IFS= read -r -d '' f; do
        DETECTED_VIDEOS+=("$f")
    done < <(find "$src_vid" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" \) -print0 2>/dev/null | sort -z)

    if [ ${#DETECTED_VIDEOS[@]} -gt 0 ]; then
        log_info "Copiando ${#DETECTED_VIDEOS[@]} video(s) desde ${src_vid}/"
        for f in "${DETECTED_VIDEOS[@]}"; do
            cp "$f" "$dst_vid/"
        done
    else
        log_warn "No se encontraron videos reales en ${src_vid}/. Generando placeholder..."
        generate_placeholder_video "$dst_vid"
    fi

    DETECTED_VIDEOS=()
    while IFS= read -r -d '' f; do
        DETECTED_VIDEOS+=("$f")
    done < <(find "$dst_vid" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)

    local vid_count=${#DETECTED_VIDEOS[@]}
    log_info "${vid_count} video(s) disponible(s)"
}

# =============================================================================
#  DETECTAR DISTRO LINUX
# =============================================================================
detect_distro() {
    local distro=""
    if [ -f /etc/os-release ]; then
        distro=$(grep -oP '^ID=\K.*' /etc/os-release 2>/dev/null | tr -d '"' | tr '[:upper:]' '[:lower:]') || true
    fi
    if [ -z "$distro" ] && command -v lsb_release &>/dev/null; then
        distro=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]') || true
    fi
    if [ -z "$distro" ] && [ -f /etc/debian_version ]; then
        distro="debian"
    elif [ -z "$distro" ] && [ -f /etc/arch-release ]; then
        distro="arch"
    elif [ -z "$distro" ] && [ -f /etc/fedora-release ]; then
        distro="fedora"
    fi
    echo "${distro:-unknown}"
}

# =============================================================================
#  INSTALAR HERRAMIENTAS DE COMPRESIÓN
# =============================================================================
install_compression_tools() {
    local distro
    distro=$(detect_distro)
    log_info "Distro detectada: ${distro}"

    if ! command -v sudo &>/dev/null; then
        log_warn "sudo no disponible. No se pueden instalar herramientas automáticamente."
        return 1
    fi

    case "$distro" in
        ubuntu|debian|linuxmint|kali|pop|elementary|neon|zorin|mx|deepin)
            log_info "Instalando herramientas vía apt..."
            sudo apt-get update -qq 2>/dev/null || true
            sudo apt-get install -y -qq imagemagick webp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        arch|manjaro|endeavouros|artix|arcolinux)
            log_info "Instalando herramientas vía pacman..."
            sudo pacman -S --noconfirm --needed imagemagick libwebp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        fedora|rhel|centos|rocky|alma)
            log_info "Instalando herramientas vía dnf..."
            sudo dnf install -y ImageMagick libwebp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        opensuse*|suse)
            log_info "Instalando herramientas vía zypper..."
            sudo zypper --non-interactive install imagemagick libwebp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        alpine)
            log_info "Instalando herramientas vía apk..."
            sudo apk add imagemagick libwebp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        void)
            log_info "Instalando herramientas vía xbps..."
            sudo xbps-install -S imagemagick libwebp jpegoptim optipng pngquant ffmpeg 2>/dev/null || {
                log_warn "Algunos paquetes no estan disponibles. Continuando con los instalados."
            }
            log_info "Herramientas instaladas correctamente"
            ;;
        *)
            log_warn "Distro '${distro}' no reconocida. Instala manualmente las herramientas."
            log_warn "Paquetes necesarios: imagemagick, webp, jpegoptim, optipng, pngquant, ffmpeg"
            return 1
            ;;
    esac
}

# =============================================================================
#  FORMATO LEGIBLE DE TAMAÑO
# =============================================================================
format_size() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        local mb=$((bytes * 100 / 1048576))
        echo "$((mb / 100)),$((mb % 100 < 10 ? 0 : 0))$((mb % 100)) MB"
    elif [ "$bytes" -ge 1024 ]; then
        local kb=$((bytes * 10 / 1024))
        echo "$((kb / 10)),$((kb % 10)) KB"
    else
        echo "${bytes} B"
    fi
}

# =============================================================================
#  OPTIMIZAR IMÁGENES
# =============================================================================
optimize_images() {
    log_step "Optimizando imágenes"

    local img_dir="${OUTPUT_DIR}/assets/img"
    local has_any=false

    # ─── Verificar herramientas disponibles ───
    for cmd in mogrify convert cwebp jpegoptim optipng; do
        if command -v "$cmd" &>/dev/null; then
            has_any=true
            break
        fi
    done

    if ! $has_any; then
        log_warn "No hay herramientas de compresión disponibles. Intentando instalar..."
        install_compression_tools || true
    fi

    # ─── Verificar nuevamente después de instalación ───
    has_any=false
    for cmd in mogrify convert cwebp jpegoptim optipng; do
        if command -v "$cmd" &>/dev/null; then
            has_any=true
            break
        fi
    done

    if ! $has_any; then
        log_warn "No hay herramientas de compresión disponibles. Continuando sin optimización."
        log_warn "Instala manualmente: ImageMagick, webp, jpegoptim, optipng"
        return
    fi

    log_info "Herramientas disponibles:"
    command -v mogrify &>/dev/null && log_info "  - mogrify (ImageMagick)"
    command -v convert &>/dev/null && log_info "  - convert (ImageMagick)"
    command -v cwebp &>/dev/null && log_info "  - cwebp (WebP)"
    command -v jpegoptim &>/dev/null && log_info "  - jpegoptim"
    command -v optipng &>/dev/null && log_info "  - optipng"
    command -v pngquant &>/dev/null && log_info "  - pngquant"

    # ─── Calcular tamaño total antes ───
    local total_before=0 total_after=0 f ext size

    for f in "$img_dir"/*; do
        [ -f "$f" ] || continue
        size=$(stat -c%s "$f" 2>/dev/null || echo 0)
        total_before=$((total_before + size))
    done

    if [ "$total_before" -eq 0 ]; then
        log_warn "No hay imágenes para optimizar en ${img_dir}"
        return
    fi

    # ─── Aplicar compresión principal con mogrify ───
    local optimized=0 skipped=0

    if command -v mogrify &>/dev/null; then
        log_info "Comprimiendo con ImageMagick (mogrify) calidad ~85%..."
        for f in "$img_dir"/*; do
            [ -f "$f" ] || continue
            ext="${f##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            case "$ext" in
                png|jpg|jpeg|webp)
                    if mogrify -strip -quality 85 "$f" 2>/dev/null; then
                        optimized=$((optimized + 1))
                    else
                        skipped=$((skipped + 1))
                    fi
                    ;;
            esac
        done
    fi

    # ─── Optimización adicional especializada ───
    if command -v jpegoptim &>/dev/null; then
        for f in "$img_dir"/*; do
            [ -f "$f" ] || continue
            ext="${f##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            case "$ext" in
                jpg|jpeg)
                    jpegoptim --strip-all --max=85 "$f" 2>/dev/null || true
                    ;;
            esac
        done
    fi

    if command -v pngquant &>/dev/null; then
        for f in "$img_dir"/*; do
            [ -f "$f" ] || continue
            ext="${f##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            case "$ext" in
                png)
                    pngquant --strip --quality 70-85 --speed 3 --force "$f" --out "$f" 2>/dev/null || true
                    ;;
            esac
        done
    fi

    if command -v optipng &>/dev/null; then
        for f in "$img_dir"/*; do
            [ -f "$f" ] || continue
            ext="${f##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            case "$ext" in
                png)
                    optipng -o2 -strip all "$f" 2>/dev/null || true
                    ;;
            esac
        done
    fi

    # ─── Calcular tamaño después ───
    for f in "$img_dir"/*; do
        [ -f "$f" ] || continue
        size=$(stat -c%s "$f" 2>/dev/null || echo 0)
        total_after=$((total_after + size))
    done

    # ─── Mostrar resultados ───
    local saved=$((total_before - total_after))
    local pct=0
    if [ "$total_before" -gt 0 ]; then
        pct=$((saved * 100 / total_before))
    fi

    local before_fmt after_fmt saved_fmt
    before_fmt=$(format_size "$total_before")
    after_fmt=$(format_size "$total_after")
    saved_fmt=$(format_size "${saved#-}")

    if [ "$saved" -gt 0 ]; then
        log_info "Optimización: ${before_fmt} → ${after_fmt} (ahorro ${saved_fmt}, ${pct}%)"
    elif [ "$saved" -lt 0 ]; then
        log_info "Optimización: ${before_fmt} → ${after_fmt} (incremento ${saved_fmt})"
    else
        log_info "Imágenes ya optimizadas (${before_fmt})"
    fi

    if [ "$skipped" -gt 0 ]; then
        log_info "${optimized} optimizada(s), ${skipped} omitida(s)"
    else
        log_info "${optimized} imagen(es) procesada(s)"
    fi
}

# =============================================================================
#  CONVERTIR VIDEOS PARA COMPATIBILIDAD WEB (ffmpeg)
# =============================================================================
convert_videos() {
    log_step "Convirtiendo videos para compatibilidad web"

    local vid_dir="${OUTPUT_DIR}/assets/video"

    if ! command -v ffmpeg &>/dev/null; then
        log_warn "ffmpeg no disponible. Intentando instalar..."
        install_compression_tools || true
    fi

    if ! command -v ffmpeg &>/dev/null; then
        log_warn "ffmpeg no disponible. Los videos se usaran sin convertir."
        return
    fi

    local converted=0 skipped=0
    local f ext basename_name tmp_output

    for f in "$vid_dir"/*; do
        [ -f "$f" ] || continue
        ext="${f##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        case "$ext" in
            mp4|webm|mov|avi|mkv|flv|m4v)
                basename_name="${f%.*}"
                tmp_output="${basename_name}.tmp.mp4"

                log_info "  Convirtiendo $(basename "$f")..."

                if ffmpeg -i "$f" \
                    -c:v libx264 \
                    -pix_fmt yuv420p \
                    -c:a aac \
                    -movflags +faststart \
                    -y "$tmp_output" 2>/dev/null; then
                    mv "$tmp_output" "${basename_name}.mp4"
                    if [ "$ext" != "mp4" ]; then
                        rm -f "$f"
                    fi
                    converted=$((converted + 1))
                else
                    log_warn "  Error al convertir $(basename "$f"). Usando original."
                    rm -f "$tmp_output"
                    skipped=$((skipped + 1))
                fi
                ;;
        esac
    done

    # Re-poblar DETECTED_VIDEOS con los nombres actualizados
    DETECTED_VIDEOS=()
    while IFS= read -r -d '' f; do
        DETECTED_VIDEOS+=("$f")
    done < <(find "$vid_dir" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)

    if [ "$converted" -gt 0 ]; then
        log_info "${converted} video(s) convertido(s) a MP4 compatible"
    fi
    if [ "$skipped" -gt 0 ]; then
        log_info "${skipped} video(s) omitido(s) por error"
    fi
}

# =============================================================================
#  GENERAR INDEX.HTML
# =============================================================================
generate_index_html() {
    log_step "Generando index.html"

    # ─── Preparar contenido dinámico ───
    local first_img=$(basename "${DETECTED_IMAGES[0]}")
    local img_count=${#DETECTED_IMAGES[@]}
    local vid_count=${#DETECTED_VIDEOS[@]}

    # Hero features HTML
    local features_html=""
    for feat in "${HERO_FEATURES[@]}"; do
        [ -n "$features_html" ] && features_html+=$'\n'
        features_html+="                    <span class=\"hf-item\">${feat}</span>"
    done

    # Gallery thumbs HTML
    local thumbs_html=""
    for ((i=0; i<img_count; i++)); do
        local fname=$(basename "${DETECTED_IMAGES[$i]}")
        local active=""
        [ $i -eq 0 ] && active=" active"
        [ -n "$thumbs_html" ] && thumbs_html+=$'\n'
        thumbs_html+="                <img src=\"assets/img/${fname}\" alt=\"${PRODUCT_NAME} - Imagen $((i+1))\" class=\"thumb${active}\" data-index=\"${i}\" loading=\"lazy\">"
    done

    # Video players HTML
    local videos_html=""
    for ((i=0; i<vid_count; i++)); do
        local fname=$(basename "${DETECTED_VIDEOS[$i]}")
        local ext="${fname##*.}"
        local mime="video/mp4"
        [ "$ext" = "webm" ] && mime="video/webm"
        local margin=""
        [ $i -gt 0 ] && margin=' style="margin-top:24px"'

        [ -n "$videos_html" ] && videos_html+=$'\n\n'
        videos_html+="                        <div class=\"video-wrapper\"${margin}>"
        videos_html+=$'\n'
        videos_html+="                            <video controls preload=\"metadata\" poster=\"assets/img/${first_img}\" playsinline>"
        videos_html+=$'\n'
        videos_html+="                                <source src=\"assets/video/${fname}\" type=\"${mime}\">"
        videos_html+=$'\n'
        videos_html+="                            </video>"
        videos_html+=$'\n'
        videos_html+="                        </div>"
    done

    local section_title_video="Video"
    local section_desc_video="Mira el ${PRODUCT_NAME} en acción"
    [ $vid_count -gt 1 ] && section_title_video="Videos" && section_desc_video="Mira el ${PRODUCT_NAME} desde todos los ángulos"

    # Variants HTML
    local variants_html=""
    for variant in "${PRODUCT_VARIANTS[@]}"; do
        IFS='|' read -r label id <<< "$variant"
        local stock_var="STOCK_$(echo "$id" | tr '[:lower:]' '[:upper:]')"
        local max="${!stock_var}"
        [ -n "$variants_html" ] && variants_html+=$'\n'
        variants_html+="                        <div class=\"variant-item\">"
        variants_html+=$'\n'
        variants_html+="                            <div class=\"variant-info\">"
        variants_html+=$'\n'
        variants_html+="                                <span class=\"variant-label\">${label}</span>"
        variants_html+=$'\n'
        variants_html+="                                <span class=\"variant-stock\"><span class=\"stock-dot\"></span> ${max} unid. disponibles</span>"
        variants_html+=$'\n'
        variants_html+="                            </div>"
        variants_html+=$'\n'
        variants_html+="                            <div class=\"quantity-selector\">"
        variants_html+=$'\n'
        variants_html+="                                <button class=\"qty-btn variant-minus\" data-id=\"${id}\" type=\"button\" aria-label=\"Reducir ${label}\">−</button>"
        variants_html+=$'\n'
        variants_html+="                                <input type=\"number\" class=\"qty-input variant-qty\" data-id=\"${id}\" value=\"0\" min=\"0\" max=\"${max}\" aria-live=\"polite\">"
        variants_html+=$'\n'
        variants_html+="                                <button class=\"qty-btn variant-plus\" data-id=\"${id}\" type=\"button\" aria-label=\"Aumentar ${label}\">+</button>"
        variants_html+=$'\n'
        variants_html+="                            </div>"
        variants_html+=$'\n'
        variants_html+="                        </div>"
    done

    # Social networks HTML
    local social_html=""
    local social_entries=()

    social_entries+=("INSTAGRAM_URL|Instagram|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"2\" y=\"2\" width=\"20\" height=\"20\" rx=\"5\"/><circle cx=\"12\" cy=\"12\" r=\"5\"/><circle cx=\"17.5\" cy=\"6.5\" r=\"1.5\" fill=\"currentColor\"/></svg>")
    social_entries+=("TIKTOK_URL|TikTok|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 18V5l12-2v13\"/><circle cx=\"6\" cy=\"18\" r=\"3\"/><circle cx=\"18\" cy=\"16\" r=\"3\"/></svg>")
    social_entries+=("YOUTUBE_URL|YouTube|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"2\" y=\"4\" width=\"20\" height=\"16\" rx=\"4\"/><polygon points=\"10,8 16,12 10,16\" fill=\"currentColor\" stroke=\"none\"/></svg>")
    social_entries+=("FACEBOOK_URL|Facebook|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"10\"/><path d=\"M16 8h-2a2 2 0 0 0-2 2v10M12 12v6\"/></svg>")
    social_entries+=("X_URL|X|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 4l16 16M20 4L4 20\"/></svg>")
    social_entries+=("TWITTER_URL|Twitter|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 4l16 16M20 4L4 20\"/></svg>")
    social_entries+=("TELEGRAM_URL|Telegram|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M22 2L11 13M22 2l-7 20-4-9-9-4z\"/></svg>")
    social_entries+=("WHATSAPP_CHANNEL_URL|WhatsApp|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M21 11.5a8.5 8.5 0 0 1-8.5 8.5H3l2.5-4A8.5 8.5 0 1 1 21 11.5z\"/></svg>")
    social_entries+=("DISCORD_URL|Discord|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 12h.01M15 12h.01M7.5 4C4.5 4 2 6.5 2 9.5v3c0 1.5.7 2.8 1.8 3.7L3 20l4.5-2.5c.8.3 1.7.5 2.5.5 3 0 5.5-2.5 5.5-5.5v-3C15.5 6.4 13 4 10 4z\"/></svg>")
    social_entries+=("TWITCH_URL|Twitch|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M2 4v12h4v4l6-4h4l6-6V4z\"/><path d=\"M9 8v4M13 8v4\"/></svg>")
    social_entries+=("THREADS_URL|Threads|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M16 12a4 4 0 0 1-8 0 4 4 0 0 1 8 0zm0 0c0 2.5 4 2 4 0s-1.5-8-7-8-7 5-7 8 2 8 7 8 6-2 6-4\"/></svg>")
    social_entries+=("LINKEDIN_URL|LinkedIn|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M16 8a6 6 0 0 1 6 6v6h-4v-6a2 2 0 0 0-4 0v6h-4v-6a6 6 0 0 1 6-6z\"/><rect x=\"2\" y=\"9\" width=\"4\" height=\"11\"/><circle cx=\"4\" cy=\"4\" r=\"2\"/></svg>")
    social_entries+=("GITHUB_URL|GitHub|<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"22\" height=\"22\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M12 0C5.4 0 0 5.4 0 12c0 5.3 3.4 9.8 8.2 11.4.6.1.8-.3.8-.6v-2.2c-3.3.7-4-1.4-4-1.4-.5-1.2-1.3-1.5-1.3-1.5-1.1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1 1.8 2.7 1.3 3.4 1 .1-.7.4-1.3.7-1.6-2.6-.3-5.3-1.3-5.3-5.7 0-1.3.5-2.4 1.2-3.2-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2 1-.3 2-.4 3-.4s2 .1 3 .4c2.3-1.5 3.3-1.2 3.3-1.2.6 1.7.2 2.9.1 3.2.7.8 1.2 1.9 1.2 3.2 0 4.4-2.7 5.4-5.3 5.7.4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6C20.6 21.8 24 17.3 24 12 24 5.4 18.6 0 12 0z\"/></svg>")

    for social_entry in "${social_entries[@]}"; do
        IFS='|' read -r var_name label svg <<< "$social_entry"
        local url="${!var_name}"
        if [ -n "$url" ]; then
            [ -n "$social_html" ] && social_html+=$'\n'
            social_html+="                <a href=\"${url}\" class=\"social-link\" target=\"_blank\" rel=\"noopener noreferrer\" aria-label=\"${label}\">${svg}<span>${label}</span></a>"
        fi
    done

    # Featured product showcase
    local featured_entries=()
    local fe_img

    if [ -n "$FEATURED_PRODUCT_1" ]; then
        for fe_img in "${DETECTED_IMAGES[@]}"; do
            if [ "$(basename "$fe_img")" = "$FEATURED_PRODUCT_1" ]; then
                featured_entries+=("${FEATURED_PRODUCT_1}|${FEATURED_PRODUCT_1_LABEL}")
                break
            fi
        done
    fi
    if [ -n "$FEATURED_PRODUCT_2" ]; then
        for fe_img in "${DETECTED_IMAGES[@]}"; do
            if [ "$(basename "$fe_img")" = "$FEATURED_PRODUCT_2" ]; then
                featured_entries+=("${FEATURED_PRODUCT_2}|${FEATURED_PRODUCT_2_LABEL}")
                break
            fi
        done
    fi

    local featured_html=""
    if [ ${#featured_entries[@]} -gt 0 ]; then
        featured_html='                <div class="product-featured" id="productFeatured">'$'\n'
        featured_html+='                    <div class="featured-blur" id="featuredBlur"></div>'$'\n'
        featured_html+='                    <div class="featured-slides">'$'\n'
        local fe_idx=0
        for fe_entry in "${featured_entries[@]}"; do
            IFS='|' read -r fe_fname fe_label <<< "$fe_entry"
            local fe_active=""
            [ $fe_idx -eq 0 ] && fe_active=" active"
            featured_html+="                        <div class=\"featured-slide${fe_active}\" data-index=\"${fe_idx}\">"$'\n'
            featured_html+="                            <img src=\"assets/img/${fe_fname}\" alt=\"${fe_label}\" loading=\"lazy\">"$'\n'
            featured_html+="                            <div class=\"featured-label\">${fe_label}</div>"$'\n'
            featured_html+="                        </div>"$'\n'
            fe_idx=$((fe_idx + 1))
        done
        featured_html+='                    </div>'$'\n'
        featured_html+='                    <div class="featured-dots" id="featuredDots">'$'\n'
        for ((fe_idx=0; fe_idx<${#featured_entries[@]}; fe_idx++)); do
            local dot_active=""
            [ $fe_idx -eq 0 ] && dot_active=" active"
            featured_html+="                        <span class=\"dot${dot_active}\" data-index=\"${fe_idx}\"></span>"$'\n'
        done
        featured_html+='                    </div>'$'\n'
        featured_html+='                </div>'
    fi

    # ─── Precio promocional ───
    local price_html=""
    if [ -n "$PROMO_PRICE" ]; then
        price_html=$(cat <<PRICEEOF
                    <div class="price-row">
                        <div class="price-promo-wrap">
                            <span class="promo-badge">🔥 OFERTA</span>
                            <span class="price-old">Bs ${PRODUCT_PRICE}</span>
                            <span class="price-promo">Bs ${PROMO_PRICE}</span>
                        </div>
                        <div class="promo-glow"></div>
                    </div>
PRICEEOF
)
    else
        price_html=$(cat <<PRICEEOF
                    <div class="product-price">Bs ${PRODUCT_PRICE}</div>
PRICEEOF
)
    fi

    # ─── Contacto secundario WhatsApp ───
    local secondary_whatsapp_html=""
    if [ -n "$SECONDARY_WHATSAPP_NUMBER" ]; then
        local secondary_display="$SECONDARY_WHATSAPP_NUMBER"
        local secondary_wa_number="$SECONDARY_WHATSAPP_NUMBER"
        if [[ "$secondary_wa_number" =~ ^[0-9]+$ ]] && [ ${#secondary_wa_number} -le 8 ]; then
            secondary_wa_number="591${secondary_wa_number}"
        fi

        local sec_tag="div"
        local sec_href=""
        local sec_extra=""
        if [ "$ENABLE_SECONDARY_WHATSAPP_LINK" = "true" ]; then
            sec_tag="a"
            sec_href=" href=\"https://wa.me/${secondary_wa_number}\""
            sec_extra=" class=\"whatsapp-secondary is-link\" target=\"_blank\" rel=\"noopener noreferrer\""
        else
            sec_extra=" class=\"whatsapp-secondary\""
        fi

        secondary_whatsapp_html=$(cat <<SECHPRO
                    <${sec_tag}${sec_href}${sec_extra}>
                        <svg class="ws-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.5 8.5 0 0 1-8.5 8.5H3l2.5-4A8.5 8.5 0 1 1 21 11.5z"/></svg>
                        <span class="ws-text-light">o comunícate al</span>
                        <span class="ws-number">${secondary_display}</span>
                    </${sec_tag}>
SECHPRO
        )
    fi

    # ─── Escribir HTML ───
    cat <<EOF > "${OUTPUT_DIR}/index.html"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${SITE_TITLE} | ${PRODUCT_NAME}</title>
    <meta name="description" content="${SITE_DESCRIPTION}">
    <meta name="author" content="${SELLER_NAME}">
    <meta name="robots" content="index, follow">
    <meta name="theme-color" content="${PRIMARY_COLOR}">
    <meta property="og:title" content="${PRODUCT_NAME} - ${SITE_TITLE}">
    <meta property="og:description" content="${SITE_DESCRIPTION}">
    <meta property="og:type" content="product">
    <meta property="og:image" content="assets/img/${first_img}">
    <meta property="og:site_name" content="${SITE_TITLE}">
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='6' fill='${PRIMARY_COLOR//#/%23}'/></svg>">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <!-- ============================== HEADER ============================== -->
    <header class="header" id="header">
        <div class="container header-inner">
            <a href="#" class="logo" aria-label="Inicio">
                <span class="logo-icon">⚡</span>
                <span class="logo-text">${SITE_TITLE}</span>
            </a>
            <nav class="nav" id="nav" role="navigation" aria-label="Navegación principal">
                <a href="#hero" class="nav-link">Inicio</a>
                <a href="#galeria" class="nav-link">Galería</a>
                <a href="#video" class="nav-link">${section_title_video}</a>
                <a href="#producto" class="nav-link">Producto</a>
                <a href="#producto" class="nav-link nav-btn">Comprar</a>
            </nav>
            <button class="nav-toggle" id="navToggle" aria-label="Abrir menú" type="button">
                <span></span><span></span><span></span>
            </button>
        </div>
    </header>

    <!-- ============================== HERO ============================== -->
    <section id="hero" class="hero">
        <div class="hero-bg-glow"></div>
        <div class="container hero-inner">
            <div class="hero-content">
                <span class="hero-badge">🛵 Nuevo lanzamiento</span>
                <h1 class="hero-title">${PRODUCT_NAME}</h1>
                <p class="hero-desc">${SITE_DESCRIPTION}</p>
                <div class="hero-actions">
                    <a href="#producto" class="btn btn-primary">Comprar ahora</a>
                    <a href="#galeria" class="btn btn-outline">Ver galería</a>
                </div>
                <div class="hero-features">
${features_html}
                </div>
            </div>
            <div class="hero-visual">
                <div class="hero-img-wrapper">
                    <img src="assets/img/${first_img}" alt="${PRODUCT_NAME}" loading="eager">
                    <div class="hero-glow"></div>
                </div>
            </div>
        </div>
    </section>

    <!-- ============================== GALERÍA ============================== -->
    <section id="galeria" class="section gallery">
        <div class="container">
            <h2 class="section-title">Galería</h2>
            <p class="section-desc">Cada detalle de nuestro parlante bluetooth TAXI</p>
            <div class="gallery-main">
                <div class="gallery-blur" id="galleryBlur" style="background-image: url('assets/img/${first_img}')"></div>
                <img id="galleryMain" src="assets/img/${first_img}" alt="${PRODUCT_NAME}">
            </div>
            <div class="gallery-thumbs" id="galleryThumbs">
${thumbs_html}
            </div>
        </div>
    </section>

    <!-- ============================== VIDEO ============================== -->
    <section id="video" class="section video-section">
        <div class="container">
            <h2 class="section-title">${section_title_video}</h2>
            <p class="section-desc">${section_desc_video}</p>
            <div class="video-grid">
${videos_html}
            </div>
        </div>
    </section>

    <!-- ============================== PRODUCTO ============================== -->
    <section id="producto" class="section product-section">
        <div class="container">
            <h2 class="section-title">Producto</h2>
            <p class="section-desc">Información y pedido</p>
            <div class="product-card">
                <div class="product-img-col">
${featured_html}
                </div>
                <div class="product-info-col">
                    <h3 class="product-name">${PRODUCT_NAME}</h3>
                    ${price_html}

                    <div class="product-variants">
                        <label class="variants-label">Cantidad por variante</label>
${variants_html}
                    </div>

                    <div class="product-field">
                        <label for="department">Departamento de entrega</label>
                        <div class="select-wrap">
                            <select id="department" class="department-select" required>
                                <option value="">— Seleccionar —</option>
                                <option value="La Paz">La Paz</option>
                                <option value="Cochabamba">Cochabamba</option>
                                <option value="Santa Cruz">Santa Cruz</option>
                                <option value="Oruro">Oruro</option>
                                <option value="Potosí">Potosí</option>
                                <option value="Chuquisaca">Chuquisaca</option>
                                <option value="Tarija">Tarija</option>
                                <option value="Beni">Beni</option>
                                <option value="Pando">Pando</option>
                            </select>
                        </div>
                    </div>

                    <button id="whatsappBtn" class="btn btn-whatsapp" type="button">
                        <span>💬</span> Pedir por WhatsApp
                    </button>
                    ${secondary_whatsapp_html}
                </div>
            </div>
        </div>
    </section>

    <!-- ============================== FOOTER ============================== -->
    <footer class="footer">
        <div class="container footer-inner">
            <div class="footer-brand">
                <span class="logo-icon">⚡</span>
                <span>${SITE_TITLE}</span>
            </div>
            <div class="footer-social">
${social_html}
            </div>
            <p class="footer-copy">© 2026 ${SITE_TITLE}. Todos los derechos reservados.</p>
        </div>
    </footer>

    <script src="js/app.js" defer></script>
</body>
</html>
EOF

    log_info "index.html generado (${img_count} imagen(es), ${vid_count} video(s))"
}

# =============================================================================
#  GENERAR CSS
# =============================================================================
generate_css() {
    log_step "Generando css/style.css"

    cat <<EOF > "${OUTPUT_DIR}/css/style.css"

/* ================================================================
   FAVIO600RR SHOP — ESTILOS v3
   ================================================================ */

/* --- Variables --- */
:root {
    --primary:   ${PRIMARY_COLOR};
    --secondary: ${SECONDARY_COLOR};
    --bg:        #0a0a0f;
    --bg2:       #111118;
    --bg3:       #181828;
    --text:      #ffffff;
    --text2:     #9898b8;
    --text3:     #5c5c7a;
    --border:    rgba(255, 255, 255, 0.06);
    --radius:    16px;
    --radius-sm: 8px;
    --shadow:    0 8px 32px rgba(0, 0, 0, 0.5);
    --shadow-lg: 0 20px 60px rgba(0, 0, 0, 0.6);
    --ease:      0.3s cubic-bezier(0.4, 0, 0.2, 1);
    --ease-slow: 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

/* --- Reset --- */
*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

html {
    scroll-behavior: smooth;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
        Oxygen, Ubuntu, Cantarell, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
    overflow-x: hidden;
}

img { max-width: 100%; display: block; }
a   { text-decoration: none; color: inherit; }
button { font-family: inherit; cursor: pointer; }

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 24px;
}

/* ============== HEADER ============== */
.header {
    position: fixed;
    top: 0; left: 0; width: 100%;
    z-index: 1000;
    background: rgba(10, 10, 15, 0.82);
    backdrop-filter: blur(24px);
    -webkit-backdrop-filter: blur(24px);
    border-bottom: 1px solid var(--border);
    padding: 14px 0;
    transition: background var(--ease), padding var(--ease);
}
.header-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.logo {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 1.2rem;
    font-weight: 700;
    letter-spacing: -0.5px;
}
.logo-icon { font-size: 1.4rem; }

.nav {
    display: flex;
    align-items: center;
    gap: 28px;
}
.nav-link {
    font-size: 0.9rem;
    color: var(--text2);
    font-weight: 500;
    transition: color var(--ease);
    position: relative;
    padding: 4px 0;
}
.nav-link::after {
    content: "";
    position: absolute;
    bottom: -2px; left: 0;
    width: 0; height: 2px;
    background: var(--primary);
    border-radius: 2px;
    transition: width var(--ease);
}
.nav-link:hover { color: var(--text); }
.nav-link:hover::after { width: 100%; }

.nav-btn {
    background: var(--primary) !important;
    color: #fff !important;
    padding: 8px 22px !important;
    border-radius: 50px !important;
    font-weight: 600 !important;
    transition: all var(--ease) !important;
}
.nav-btn:hover {
    background: #ff8c5a !important;
    transform: translateY(-1px);
    box-shadow: 0 4px 20px rgba(255, 107, 53, 0.35);
}
.nav-btn::after { display: none !important; }

/* --- Nav Toggle --- */
.nav-toggle {
    display: none;
    flex-direction: column;
    gap: 5px;
    background: none;
    border: none;
    padding: 4px;
    z-index: 1001;
}
.nav-toggle span {
    display: block;
    width: 24px; height: 2px;
    background: var(--text);
    border-radius: 2px;
    transition: all var(--ease);
}
.nav-toggle.active span:nth-child(1) { transform: rotate(45deg) translate(5px, 5px); }
.nav-toggle.active span:nth-child(2) { opacity: 0; }
.nav-toggle.active span:nth-child(3) { transform: rotate(-45deg) translate(5px, -5px); }

/* ============== HERO ============== */
.hero {
    min-height: 100vh;
    display: flex;
    align-items: center;
    padding-top: 80px;
    position: relative;
    overflow: hidden;
}
.hero-bg-glow {
    position: absolute;
    top: -30%; right: -10%;
    width: 800px; height: 800px;
    background: radial-gradient(circle, rgba(255, 107, 53, 0.08), transparent 70%);
    pointer-events: none;
}
.hero-inner {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 60px;
    align-items: center;
    position: relative;
    z-index: 1;
}
.hero-content { display: flex; flex-direction: column; }

.hero-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    width: fit-content;
    padding: 6px 18px;
    background: rgba(255, 107, 53, 0.12);
    color: var(--primary);
    border-radius: 50px;
    font-size: 0.85rem;
    font-weight: 600;
    margin-bottom: 20px;
    border: 1px solid rgba(255, 107, 53, 0.2);
}

.hero-title {
    font-size: 3.4rem;
    font-weight: 800;
    line-height: 1.12;
    margin-bottom: 16px;
    background: linear-gradient(135deg, #fff 30%, var(--primary) 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    letter-spacing: -1px;
}

.hero-desc {
    font-size: 1.1rem;
    color: var(--text2);
    margin-bottom: 32px;
    max-width: 480px;
    line-height: 1.7;
}

.hero-actions {
    display: flex;
    gap: 16px;
    margin-bottom: 40px;
    flex-wrap: wrap;
}

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 14px 34px;
    border-radius: 50px;
    font-weight: 600;
    font-size: 1rem;
    border: none;
    transition: all var(--ease);
    text-align: center;
}
.btn-primary {
    background: linear-gradient(135deg, var(--primary), #ff8c5a);
    color: #fff;
    box-shadow: 0 4px 24px rgba(255, 107, 53, 0.35);
}
.btn-primary:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 40px rgba(255, 107, 53, 0.5);
}
.btn-outline {
    background: transparent;
    color: var(--text);
    border: 1px solid rgba(255, 255, 255, 0.15);
}
.btn-outline:hover {
    border-color: var(--primary);
    background: rgba(255, 107, 53, 0.08);
    color: var(--primary);
}

.hero-features {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
}
.hf-item {
    color: var(--text2);
    font-size: 0.85rem;
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 6px 14px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid var(--border);
    border-radius: 50px;
    transition: all var(--ease);
}
.hf-item:hover {
    border-color: rgba(255, 107, 53, 0.3);
    background: rgba(255, 107, 53, 0.06);
    color: var(--text);
    transform: translateY(-1px);
}

.hero-visual {
    display: flex;
    justify-content: center;
    align-items: center;
}
.hero-img-wrapper {
    position: relative;
    display: flex;
    justify-content: center;
    align-items: center;
}
.hero-img-wrapper img {
    width: 100%;
    max-width: 520px;
    border-radius: var(--radius);
    box-shadow: var(--shadow-lg);
    background: linear-gradient(135deg, var(--bg3), var(--bg2));
    animation: float 6s ease-in-out infinite;
}
.hero-glow {
    position: absolute;
    width: 350px; height: 350px;
    background: radial-gradient(circle, rgba(255, 107, 53, 0.15), transparent 70%);
    border-radius: 50%;
    z-index: -1;
    animation: pulse 4s ease-in-out infinite;
}

@keyframes float {
    0%, 100% { transform: translateY(0); }
    50%      { transform: translateY(-18px); }
}
@keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 0.3; }
    50%      { transform: scale(1.3); opacity: 0.6; }
}

/* ============== SECCIONES ============== */
.section { padding: 100px 0; }
.section-title {
    font-size: 2.2rem;
    font-weight: 700;
    text-align: center;
    margin-bottom: 12px;
    letter-spacing: -0.5px;
}
.section-desc {
    text-align: center;
    color: var(--text2);
    margin-bottom: 48px;
    font-size: 1.05rem;
}

/* ============== GALERÍA ============== */
.gallery { background: var(--bg2); }

.gallery-main {
    max-width: 720px;
    margin: 0 auto 28px;
    border-radius: var(--radius);
    overflow: hidden;
    box-shadow: var(--shadow);
    background: var(--bg);
    position: relative;
    touch-action: pan-y;
}
.gallery-main img {
    width: 100%;
    height: auto;
    max-height: 65vh;
    object-fit: contain;
    transition: transform var(--ease-slow), opacity 0.3s ease;
    display: block;
    position: relative;
    z-index: 1;
}
.gallery-main:hover img { transform: scale(1.02); }

.gallery-blur {
    position: absolute;
    inset: -60px;
    background-size: cover;
    background-position: center;
    filter: blur(30px) brightness(0.4) saturate(1.2);
    opacity: 0.7;
    z-index: 0;
    pointer-events: none;
    transition: opacity 0.3s ease;
    will-change: transform;
}

.gallery-thumbs {
    display: flex;
    gap: 12px;
    justify-content: center;
    flex-wrap: wrap;
}
.thumb {
    width: 90px;
    aspect-ratio: 3/4;
    object-fit: cover;
    border-radius: var(--radius-sm);
    cursor: pointer;
    border: 2px solid transparent;
    transition: all var(--ease);
    opacity: 0.5;
    background: linear-gradient(135deg, var(--bg3), var(--bg2));
}
.thumb:hover {
    opacity: 0.9;
    border-color: var(--primary);
    transform: translateY(-3px);
}
.thumb.active {
    opacity: 1;
    border-color: var(--primary);
    box-shadow: 0 0 24px rgba(255, 107, 53, 0.25);
}



/* ============== VIDEO ============== */
.video-section { background: var(--bg); }

.video-grid {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 24px;
}

.video-wrapper {
    width: 100%;
    max-width: 800px;
    border-radius: var(--radius);
    overflow: hidden;
    box-shadow: var(--shadow-lg);
    background: #000;
    display: flex;
    align-items: center;
    justify-content: center;
}

.video-wrapper video {
    width: 100%;
    aspect-ratio: 16 / 9;
    object-fit: contain;
    display: block;
    background: #000;
}

/* ============== PRODUCTO ============== */
.product-section { background: var(--bg2); }

.product-card {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 48px;
    background: var(--bg3);
    border-radius: var(--radius);
    padding: 48px;
    border: 1px solid var(--border);
    max-width: 1000px;
    margin: 0 auto;
    box-shadow: var(--shadow);
}
.product-img-col img {
    width: 100%;
    border-radius: var(--radius-sm);
    background: linear-gradient(135deg, var(--bg2), var(--bg));
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}
.product-name {
    font-size: 1.8rem;
    font-weight: 700;
    margin-bottom: 16px;
    line-height: 1.3;
}
.product-price {
    font-size: 2.8rem;
    font-weight: 800;
    color: var(--primary);
    margin-bottom: 20px;
    letter-spacing: -1px;
}
.product-stock { margin-bottom: 28px; }
.stock-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 18px;
    border-radius: 50px;
    font-size: 0.9rem;
    font-weight: 500;
    background: rgba(50, 220, 100, 0.12);
    color: #32dc64;
    border: 1px solid rgba(50, 220, 100, 0.2);
}

/* --- Precio promocional --- */
.price-row {
    position: relative;
    margin-bottom: 20px;
    overflow: hidden;
}
.price-promo-wrap {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    gap: 14px;
    flex-wrap: wrap;
    background: linear-gradient(135deg, rgba(255, 107, 53, 0.08), rgba(255, 68, 68, 0.04));
    border: 1px solid rgba(255, 107, 53, 0.15);
    border-radius: var(--radius);
    padding: 18px 22px;
}
.price-old {
    font-size: 1.3rem;
    color: var(--text3);
    text-decoration: line-through;
    font-weight: 500;
    order: 2;
}
.price-promo {
    font-size: 2.6rem;
    font-weight: 800;
    color: var(--primary);
    letter-spacing: -1px;
    order: 3;
}
.promo-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 5px 16px;
    background: linear-gradient(135deg, #ff6b35, #ff4444);
    color: #fff;
    border-radius: 50px;
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
    order: 1;
    box-shadow: 0 2px 12px rgba(255, 68, 68, 0.3);
}
.promo-glow {
    position: absolute;
    top: -50%;
    right: -10%;
    width: 200px;
    height: 200px;
    background: radial-gradient(circle, rgba(255, 107, 53, 0.12), transparent 70%);
    pointer-events: none;
}

/* --- Stock por variante --- */
.variant-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
}
.variant-stock {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 0.85rem;
    color: var(--text2);
    font-weight: 500;
}
.stock-dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #32dc64;
    box-shadow: 0 0 6px rgba(50, 220, 100, 0.5);
    flex-shrink: 0;
}

/* --- Featured product showcase --- */
.product-featured {
    position: relative;
    overflow: hidden;
    border-radius: var(--radius-sm);
    background: linear-gradient(135deg, var(--bg2), var(--bg));
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
    width: 100%;
}
.featured-slides {
    position: relative;
    width: 100%;
    aspect-ratio: 4 / 3;
    overflow: hidden;
}
.featured-slide {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    opacity: 0;
    visibility: hidden;
    transition: opacity 0.6s ease, visibility 0.6s ease;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}
.featured-slide.active {
    opacity: 1;
    visibility: visible;
    position: relative;
}
.featured-slide img {
    width: 100%;
    height: 100%;
    object-fit: contain;
    display: block;
    transition: transform 0.4s ease;
}
.featured-slide:hover img {
    transform: scale(1.03);
}
.featured-blur {
    position: absolute;
    inset: -40px;
    background-size: cover;
    background-position: center;
    filter: blur(24px) brightness(0.35) saturate(1.1);
    opacity: 0.6;
    z-index: 0;
    pointer-events: none;
    transition: opacity 0.4s ease;
    will-change: transform;
}
.featured-label {
    position: absolute;
    bottom: 0; left: 0; right: 0;
    padding: 14px 18px;
    background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
    color: #fff;
    font-size: 0.95rem;
    font-weight: 600;
    text-align: center;
    letter-spacing: 0.3px;
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
}
.featured-dots {
    display: flex;
    justify-content: center;
    gap: 8px;
    padding: 14px 0 6px;
}
.featured-dots .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: var(--text3);
    border: none;
    cursor: pointer;
    transition: all 0.3s ease;
    padding: 0;
}
.featured-dots .dot.active {
    background: var(--primary);
    width: 28px;
    border-radius: 4px;
}
.featured-dots .dot:hover {
    background: var(--text2);
}

.product-field { margin-bottom: 22px; }
.product-field label {
    display: block;
    margin-bottom: 10px;
    color: var(--text2);
    font-size: 0.9rem;
    font-weight: 500;
}

.product-variants { margin-bottom: 22px; }
.variants-label {
    display: block;
    margin-bottom: 14px;
    color: var(--text2);
    font-size: 0.9rem;
    font-weight: 500;
}
.variant-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    margin-bottom: 10px;
}
.variant-item:last-child { margin-bottom: 0; }
.variant-label {
    font-size: 0.95rem;
    font-weight: 600;
    color: var(--text);
}

.quantity-selector {
    display: inline-flex;
    align-items: center;
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    overflow: hidden;
    background: var(--bg2);
}
.qty-btn {
    background: transparent;
    border: none;
    color: var(--text);
    width: 46px; height: 46px;
    font-size: 1.3rem;
    transition: all var(--ease);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.qty-btn:hover { background: var(--primary); color: #fff; }
.qty-btn:disabled { opacity: 0.3; cursor: not-allowed; }

.qty-input {
    width: 64px;
    text-align: center;
    font-size: 1.15rem;
    font-weight: 600;
    background: var(--bg3);
    border: none;
    color: var(--text);
    height: 46px;
    outline: none;
    -moz-appearance: textfield;
}
.qty-input::-webkit-inner-spin-button,
.qty-input::-webkit-outer-spin-button {
    -webkit-appearance: none;
    margin: 0;
}

.select-wrap { position: relative; max-width: 360px; }
.department-select {
    width: 100%;
    padding: 12px 40px 12px 16px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    color: var(--text);
    font-size: 0.95rem;
    transition: border-color var(--ease);
    appearance: none;
    -webkit-appearance: none;
    cursor: pointer;
}
.select-wrap::after {
    content: "";
    position: absolute;
    right: 14px; top: 50%;
    width: 10px; height: 10px;
    border-right: 2px solid var(--text3);
    border-bottom: 2px solid var(--text3);
    transform: translateY(-70%) rotate(45deg);
    pointer-events: none;
}
.department-select:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(255, 107, 53, 0.1);
}
.department-select option { background: var(--bg2); color: var(--text); }

.btn-whatsapp {
    background: #25d366;
    color: #fff;
    width: 100%;
    justify-content: center;
    padding: 16px 32px;
    font-size: 1.1rem;
    font-weight: 700;
    box-shadow: 0 4px 24px rgba(37, 211, 102, 0.25);
}
.btn-whatsapp:hover {
    background: #20bd5a;
    transform: translateY(-2px);
    box-shadow: 0 8px 36px rgba(37, 211, 102, 0.4);
}
.btn-whatsapp:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

/* --- Contacto secundario WhatsApp --- */
.whatsapp-secondary {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    margin-top: 20px;
    padding: 16px 24px;
    border-radius: 14px;
    background: linear-gradient(135deg, rgba(37, 211, 102, 0.07), rgba(37, 211, 102, 0.03));
    border: 1px solid rgba(37, 211, 102, 0.18);
    color: var(--text);
    font-size: 1rem;
    font-weight: 500;
    transition: all var(--ease);
    text-decoration: none;
}
.whatsapp-secondary .ws-icon {
    width: 22px;
    height: 22px;
    color: #25d366;
    flex-shrink: 0;
    transition: transform var(--ease);
}
.whatsapp-secondary .ws-text-light {
    color: var(--text2);
    font-weight: 400;
    font-size: 0.95rem;
}
.whatsapp-secondary .ws-number {
    color: #25d366;
    font-weight: 800;
    font-size: 1.2rem;
    letter-spacing: 0.5px;
}
.whatsapp-secondary.is-link {
    cursor: pointer;
}
.whatsapp-secondary.is-link:hover {
    background: linear-gradient(135deg, rgba(37, 211, 102, 0.14), rgba(37, 211, 102, 0.06));
    border-color: rgba(37, 211, 102, 0.35);
    transform: translateY(-2px);
    box-shadow: 0 8px 28px rgba(37, 211, 102, 0.18);
}
.whatsapp-secondary.is-link:hover .ws-icon {
    transform: scale(1.1);
}

/* ============== FOOTER ============== */
.footer {
    background: var(--bg);
    padding: 48px 0;
    border-top: 1px solid var(--border);
}
.footer-inner { text-align: center; }
.footer-brand {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    font-size: 1.2rem;
    font-weight: 700;
    margin-bottom: 20px;
}
.footer-social {
    display: flex;
    justify-content: center;
    gap: 12px;
    margin-bottom: 20px;
    flex-wrap: wrap;
}
.social-link {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    color: var(--text3);
    font-size: 0.9rem;
    font-weight: 500;
    border: 1px solid var(--border);
    border-radius: 50px;
    transition: all var(--ease);
    text-decoration: none;
}
.social-link svg {
    flex-shrink: 0;
    transition: transform var(--ease);
}
.social-link:hover {
    color: var(--text);
    border-color: rgba(255, 255, 255, 0.12);
    background: var(--bg3);
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
}
.social-link:hover svg {
    transform: scale(1.15);
}
.footer-copy { color: var(--text3); font-size: 0.85rem; }

/* ============== SCROLL REVEAL ============== */
.reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.7s ease, transform 0.7s ease;
}
.reveal.active { opacity: 1; transform: translateY(0); }

/* ============== RESPONSIVE: TABLET ============== */
@media (max-width: 768px) {
    .container { padding: 0 20px; }

    .nav {
        position: fixed;
        top: 0; right: -100%;
        width: 280px; height: 100vh;
        background: var(--bg2);
        flex-direction: column;
        padding: 80px 28px 28px;
        transition: right var(--ease);
        border-left: 1px solid var(--border);
        gap: 20px;
        align-items: flex-start;
    }
    .nav.open { right: 0; }
    .nav-toggle { display: flex; }

    .hero { min-height: auto; padding: 100px 0 60px; }
    .hero-inner { grid-template-columns: 1fr; gap: 40px; text-align: center; }
    .hero-content { align-items: center; }
    .hero-title { font-size: 2.4rem; }
    .hero-desc { max-width: 100%; }
    .hero-actions { justify-content: center; }
    .hero-features { justify-content: center; }
    .hero-img-wrapper img { max-width: 380px; }

    .section { padding: 70px 0; }
    .section-title { font-size: 1.8rem; }
    .gallery-main img { max-height: 50vh; }
    .thumb { width: 70px; }

    .product-card { grid-template-columns: 1fr; gap: 32px; padding: 32px; }
    .product-price { font-size: 2.2rem; }
    .price-promo { font-size: 2rem; }
    .price-old { font-size: 1.1rem; }
    .price-promo-wrap { padding: 14px 16px; }
}

/* ============== RESPONSIVE: MOBILE ============== */
@media (max-width: 480px) {
    .container { padding: 0 16px; }
    .hero-title { font-size: 1.8rem; }
    .hero-desc { font-size: 0.95rem; }
    .hero-actions { flex-direction: column; align-items: stretch; }
    .btn { padding: 14px 24px; font-size: 0.95rem; }
    .hf-item { font-size: 0.8rem; padding: 5px 12px; }
    .hero-features { gap: 10px; }
    .hero-img-wrapper img { max-width: 280px; }

    .section { padding: 50px 0; }
    .section-title { font-size: 1.5rem; }
    .section-desc { font-size: 0.95rem; margin-bottom: 32px; }
    .gallery-main img { max-height: 40vh; }
    .gallery-thumbs { gap: 8px; }
    .thumb { width: 54px; }

    .product-card { padding: 20px; }
    .product-name { font-size: 1.4rem; }
    .product-price { font-size: 1.8rem; }
    .price-promo { font-size: 1.6rem; }
    .price-old { font-size: 0.95rem; }
    .price-promo-wrap { padding: 12px 14px; gap: 10px; }
    .promo-badge { font-size: 0.7rem; padding: 4px 12px; }
    .qty-btn { width: 40px; height: 40px; }
    .qty-input { width: 54px; height: 40px; font-size: 1rem; }
    .whatsapp-secondary { font-size: 0.9rem; padding: 14px 18px; gap: 10px; }
    .whatsapp-secondary .ws-icon { width: 20px; height: 20px; }
    .whatsapp-secondary .ws-number { font-size: 1.1rem; }

    .video-wrapper video { aspect-ratio: 16 / 9; }

    .footer-social { gap: 8px; }
    .social-link { font-size: 0.85rem; padding: 6px 12px; }
}
EOF

    log_info "css/style.css generado"
}

# =============================================================================
#  GENERAR JS
# =============================================================================
generate_js() {
    log_step "Generando js/app.js"

    # ─── Arrays dinámicos en JS ───
    local imgs_json=""
    for f in "${DETECTED_IMAGES[@]}"; do
        local name=$(basename "$f")
        if [ -n "$imgs_json" ]; then imgs_json+=","; fi
        imgs_json+="\"assets/img/${name}\""
    done

    local vids_json=""
    for f in "${DETECTED_VIDEOS[@]}"; do
        local name=$(basename "$f")
        if [ -n "$vids_json" ]; then vids_json+=","; fi
        vids_json+="{ src: \"assets/video/${name}\" }"
    done

    local variants_json=""
    for variant in "${PRODUCT_VARIANTS[@]}"; do
        IFS='|' read -r label id <<< "$variant"
        local stock_var="STOCK_$(echo "$id" | tr '[:lower:]' '[:upper:]')"
        local max="${!stock_var}"
        if [ -n "$variants_json" ]; then variants_json+=","; fi
        variants_json+="{ id: \"${id}\", label: \"${label}\", qty: 0, max: ${max} }"
    done

    cat <<EOF > "${OUTPUT_DIR}/js/app.js"

/* ================================================================
   FAVIO600RR SHOP — FUNCIONALIDAD v3
   ================================================================ */

(function () {
    "use strict";

    var CONFIG = {
        productName:    "$PRODUCT_NAME",
        productPrice:   "$PRODUCT_PRICE",
        promoPrice:     "${PROMO_PRICE}",
        productStock:   $TOTAL_STOCK,
        featuredInterval: ${FEATURED_ROTATION_INTERVAL:-5000},
        whatsappNumber: "$WHATSAPP_NUMBER",
        sellerName:     "$SELLER_NAME"
    };

    var GALLERY_IMAGES = [${imgs_json}];
    var VIDEOS         = [${vids_json}];
    var VARIANTS       = [${variants_json}];

    var currentIndex = 0;

    /* --- Init --- */
    document.addEventListener("DOMContentLoaded", function () {
        initImageFallback();
        initGallery();
        initGallerySwipe();
        initVariants();
        initWhatsApp();
        initNav();
        initReveal();
        initVideos();
        initFeatured();
        initFeaturedSwipe();
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
            var blurEl = document.getElementById("galleryBlur");
            if (blurEl) blurEl.style.backgroundImage = "url('" + GALLERY_IMAGES[index] + "')";
        }, 280);
    }

    /* --- Swipe helper --- */
    function initSwipe(el, onLeft, onRight) {
        if (!el) return;
        var startX = 0, startY = 0;
        el.addEventListener("touchstart", function (e) {
            var t = e.touches[0];
            startX = t.clientX;
            startY = t.clientY;
        }, { passive: true });
        el.addEventListener("touchend", function (e) {
            if (!startX) return;
            var t = e.changedTouches[0];
            var dx = t.clientX - startX;
            var dy = t.clientY - startY;
            if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) * 1.5) {
                if (dx > 0) onRight();
                else onLeft();
            }
            startX = 0;
            startY = 0;
        }, { passive: true });
    }

    /* --- Gallery swipe --- */
    function initGallerySwipe() {
        var el = document.querySelector(".gallery-main");
        var thumbs = document.querySelectorAll(".thumb");
        if (!el || !thumbs.length) return;
        initSwipe(el,
            function () {
                var mainImg = document.getElementById("galleryMain");
                var target = currentIndex + 1;
                if (target >= GALLERY_IMAGES.length) return;
                if (!mainImg) return;
                changeImage(target, mainImg, thumbs);
            },
            function () {
                var mainImg = document.getElementById("galleryMain");
                var target = currentIndex - 1;
                if (target < 0) return;
                if (!mainImg) return;
                changeImage(target, mainImg, thumbs);
            }
        );
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

        var state = { current: 0, slides: slides, dots: dots };
        container._featState = state;

        function goTo(index) {
            if (index === state.current) return;
            slides[state.current].classList.remove("active");
            if (dots.length) dots[state.current].classList.remove("active");
            state.current = index;
            slides[index].classList.add("active");
            if (dots.length) dots[index].classList.add("active");
            updateFeaturedBlur(index);
        }
        state.goTo = goTo;

        if (dots.length) {
            for (var i = 0; i < dots.length; i++) {
                (function (idx) {
                    dots[idx].addEventListener("click", function () { goTo(idx); });
                })(i);
            }
        }

        setInterval(function () {
            var next = (state.current + 1) % slides.length;
            goTo(next);
        }, CONFIG.featuredInterval);

        updateFeaturedBlur(0);
    }

    function updateFeaturedBlur(index) {
        var blurEl = document.getElementById("featuredBlur");
        if (!blurEl) return;
        var slides = document.querySelectorAll(".featured-slide");
        var img = slides[index] && slides[index].querySelector("img");
        if (img) {
            blurEl.style.backgroundImage = "url('" + img.src + "')";
            blurEl.style.opacity = "0.6";
        }
    }

    /* --- Featured swipe --- */
    function initFeaturedSwipe() {
        var container = document.getElementById("productFeatured");
        if (!container) return;
        var slides = container.querySelectorAll(".featured-slide");
        if (slides.length < 2) return;
        initSwipe(container,
            function () {
                var state = container._featState;
                if (!state) return;
                var next = (state.current + 1) % slides.length;
                state.goTo(next);
            },
            function () {
                var state = container._featState;
                if (!state) return;
                var prev = (state.current - 1 + slides.length) % slides.length;
                state.goTo(prev);
            }
        );
    }

    /* --- Keyboard navigation --- */
    function initKeyboardNav() {
        var scrollLock = 0;
        var scrollDelay = 700;
        var sections = [];
        var all = document.querySelectorAll("section[id]");
        for (var i = 0; i < all.length; i++) sections.push(all[i]);

        function shouldIgnore(el) {
            var tag = el.tagName.toLowerCase();
            return tag === "input" || tag === "textarea" || tag === "select" || el.isContentEditable;
        }

        function isGalleryVisible() {
            var gal = document.getElementById("galeria");
            if (!gal) return false;
            var r = gal.getBoundingClientRect();
            return r.top < window.innerHeight && r.bottom > 0;
        }

        document.addEventListener("keydown", function (e) {
            if (shouldIgnore(e.target)) return;
            var key = e.key;

            if ((key === "ArrowLeft" || key === "ArrowRight") && isGalleryVisible()) {
                e.preventDefault();
                var mainImg = document.getElementById("galleryMain");
                var thumbs  = document.querySelectorAll(".thumb");
                if (!mainImg || !thumbs.length) return;
                var target = key === "ArrowRight" ? currentIndex + 1 : currentIndex - 1;
                if (target < 0 || target >= GALLERY_IMAGES.length) return;
                changeImage(target, mainImg, thumbs);
                return;
            }

            if (key !== "ArrowDown" && key !== "ArrowUp" && key !== "PageDown" && key !== "PageUp") return;
            var now = Date.now();
            if (now - scrollLock < scrollDelay) return;
            scrollLock = now;
            e.preventDefault();

            var current = 0;
            var bestVisible = 0;
            var h = window.innerHeight;

            for (var i = 0; i < sections.length; i++) {
                var r = sections[i].getBoundingClientRect();
                var visible = Math.max(0, Math.min(h, r.bottom) - Math.max(0, r.top));
                if (visible > bestVisible) {
                    bestVisible = visible;
                    current = i;
                }
            }

            var target = key === "ArrowDown" || key === "PageDown" ? current + 1 : current - 1;
            if (target < 0 || target >= sections.length) return;

            sections[target].scrollIntoView({ behavior: "smooth", block: "start" });
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
EOF

    log_info "js/app.js generado (${#DETECTED_IMAGES[@]} imágenes, ${#DETECTED_VIDEOS[@]} videos)"
}

# =============================================================================
#  MOSTRAR RESUMEN
# =============================================================================
print_summary() {
    local first_img=$(basename "${DETECTED_IMAGES[0]}")
    local first_vid=$(basename "${DETECTED_VIDEOS[0]}")

    echo ""
    echo -e " ============================================================"
    echo -e "   ${C_GREEN}PROYECTO GENERADO CON ÉXITO${C_RESET}"
    echo -e " ============================================================"
    echo ""
    echo -e "   ${C_BOLD}Directorio de salida:${C_RESET} ${OUTPUT_DIR}/"
    echo ""
    echo -e "   ${C_BOLD}Estructura creada:${C_RESET}"
    echo -e "   ─────────────────────────────────────────────"
    echo -e "   ${OUTPUT_DIR}/"
    echo -e "   ├── index.html"
    echo -e "   ├── css/style.css"
    echo -e "   ├── js/app.js"
    echo -e "   └── assets/"
    echo -e "       ├── img/  (${#DETECTED_IMAGES[@]} archivo(s))"
    echo -e "       │   └── ${first_img} …"
    echo -e "       └── video/ (${#DETECTED_VIDEOS[@]} archivo(s))"
    echo -e "           └── ${first_vid} …"
    echo ""
    echo -e "   ${C_BOLD}Assets detectados:${C_RESET}"
    echo -e "   - ${#DETECTED_IMAGES[@]} imagen(es)"
    echo -e "   - ${#DETECTED_VIDEOS[@]} video(s)"
    echo -e "   - ${#HERO_FEATURES[@]} hero feature(s)"
    echo ""
    echo -e "   ${C_BOLD}Para publicar:${C_RESET}"
    echo -e "   1. Crea repo en GitHub y sube el código"
    echo -e "   2. Ve a Settings > Pages > Source > GitHub Actions"
    echo -e "   3. El workflow desplegará automáticamente"
    echo -e "   4. Tu sitio en: https://favio600rr.github.io/"
    echo ""
    echo -e "   ${C_BOLD}Personalización:${C_RESET}"
    echo -e "   Edita las variables en CONFIGURACIÓN de generar.sh"
    echo -e "   Coloca tus assets en assets/img/ y assets/video/"
    echo -e "   Luego ejecuta: ./generar.sh"
    echo ""
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    echo ""
    echo -e " ============================================================"
    echo -e "   ${C_CYAN}${SITE_TITLE} — Generador v${SCRIPT_VERSION}${C_RESET}"
    echo -e " ============================================================"
    echo ""

    verify_dependencies
    clean_previous_build
    create_directories
    detect_assets
    optimize_images
    convert_videos
    generate_index_html
    generate_css
    generate_js
    print_summary
}

main "$@"
