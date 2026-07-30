import { Controller } from "@hotwired/stimulus"

const WEEKDAY_NAMES = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]
const SVG_NS = "http://www.w3.org/2000/svg"

export default class extends Controller {
    static values = {
        dailyViews: Array,
        dailySubscribers: Array,
        completionBuckets: Object
    }

    static targets = [
        "viewsChart", "subsChart", "weekdayChart", "completionChart",
        "statViews", "statViewsDelta", "statSubs", "statSubsDelta",
        "tabPanelOverview", "tabPanelVideos"
    ]

    connect() {
        this.currentDays = 7
        this.redraw()
    }

    setRange(event) {
        this.element.querySelectorAll(".range-filter__btn").forEach((btn) => btn.classList.remove("is-active"))
        event.currentTarget.classList.add("is-active")
        this.currentDays = Number(event.currentTarget.dataset.range)
        this.redraw()
    }

    switchTab(event) {
        this.element.querySelectorAll(".tab-btn").forEach((btn) => btn.classList.remove("is-active"))
        event.currentTarget.classList.add("is-active")

        const tab = event.currentTarget.dataset.tab
        this.tabPanelOverviewTarget.classList.toggle("is-active", tab === "overview")
        this.tabPanelVideosTarget.classList.toggle("is-active", tab === "videos")

        if (tab === "overview") this.redraw() // chart widths need remeasuring once the panel is visible again
    }

    redraw() {
        const views = this.sliceRange(this.dailyViewsValue, this.currentDays)
        const subs = this.sliceRange(this.dailySubscribersValue, this.currentDays)

        this.renderStats(views, subs)
        this.renderLineChart(this.viewsChartTarget, views)
        this.renderLineChart(this.subsChartTarget, subs)
        this.renderWeekdayChart(views)

        const bucketData = Object.entries(this.completionBucketsValue).map(([label, value]) => ({ label, value }))
        this.renderBarChart(this.completionChartTarget, bucketData)
    }

    sliceRange(series, days) {
        return series.slice(series.length - days)
    }

    renderStats(views, subs) {
        const totalViews = views.reduce((sum, d) => sum + d.value, 0)
        const subGrowth = subs[subs.length - 1].value - subs[0].value

        this.statViewsTarget.textContent = totalViews.toLocaleString()
        this.statViewsDeltaTarget.textContent = `▲ last ${this.currentDays}d`

        this.statSubsTarget.textContent = subs[subs.length - 1].value.toLocaleString()
        this.statSubsDeltaTarget.textContent = `${subGrowth >= 0 ? "▲" : "▼"} ${Math.abs(subGrowth)} this period`
        this.statSubsDeltaTarget.classList.toggle("stat-tile__delta--up", subGrowth >= 0)
        this.statSubsDeltaTarget.classList.toggle("stat-tile__delta--down", subGrowth < 0)
    }

    renderWeekdayChart(views) {
        const sums = [ 0, 0, 0, 0, 0, 0, 0 ]
        const counts = [ 0, 0, 0, 0, 0, 0, 0 ]
        views.forEach((d) => {
            const weekday = new Date(d.date).getUTCDay()
            sums[weekday] += d.value
            counts[weekday]++
        })
        const data = WEEKDAY_NAMES.map((name, i) => ({ label: name, value: counts[i] ? Math.round(sums[i] / counts[i]) : 0 }))
        this.renderBarChart(this.weekdayChartTarget, data)
    }

    formatDateLabel(isoDate) {
        return new Date(isoDate).toLocaleDateString(undefined, { month: "short", day: "numeric", timeZone: "UTC" })
    }

    // ---------- SVG line/area chart with hover crosshair ----------
    renderLineChart(container, data) {
        container.innerHTML = ""
        const w = container.clientWidth || 600, h = 200
        const padL = 40, padR = 12, padT = 12, padB = 22
        const innerW = w - padL - padR, innerH = h - padT - padB
        const maxV = Math.max(...data.map((d) => d.value), 1) * 1.1
        const x = (i) => padL + (i / (data.length - 1)) * innerW
        const y = (v) => padT + innerH - (v / maxV) * innerH

        const svg = document.createElementNS(SVG_NS, "svg")
        svg.setAttribute("viewBox", `0 0 ${w} ${h}`)
        svg.setAttribute("width", "100%")
        svg.setAttribute("height", h)
        svg.style.display = "block"
        svg.style.overflow = "visible"

        for (let g = 0; g < 3; g++) {
            const gv = maxV * (g / 2)
            const line = document.createElementNS(SVG_NS, "line")
            line.setAttribute("x1", padL); line.setAttribute("x2", w - padR)
            line.setAttribute("y1", y(gv)); line.setAttribute("y2", y(gv))
            line.setAttribute("class", "chart-grid-line")
            svg.appendChild(line)
        }

        const tickCount = 5
        for (let t = 0; t < tickCount; t++) {
            const idx = Math.round((data.length - 1) * (t / (tickCount - 1)))
            const label = document.createElementNS(SVG_NS, "text")
            label.setAttribute("x", x(idx)); label.setAttribute("y", h - 4)
            label.setAttribute("text-anchor", t === 0 ? "start" : t === tickCount - 1 ? "end" : "middle")
            label.setAttribute("class", "chart-axis-label")
            label.textContent = this.formatDateLabel(data[idx].date)
            svg.appendChild(label)
        }

        let areaD = `M ${x(0)} ${y(data[0].value)}`
        data.forEach((d, i) => { if (i > 0) areaD += ` L ${x(i)} ${y(d.value)}` })
        areaD += ` L ${x(data.length - 1)} ${y(0)} L ${x(0)} ${y(0)} Z`
        const area = document.createElementNS(SVG_NS, "path")
        area.setAttribute("d", areaD); area.setAttribute("class", "chart-area")
        svg.appendChild(area)

        let lineD = `M ${x(0)} ${y(data[0].value)}`
        data.forEach((d, i) => { if (i > 0) lineD += ` L ${x(i)} ${y(d.value)}` })
        const line = document.createElementNS(SVG_NS, "path")
        line.setAttribute("d", lineD); line.setAttribute("class", "chart-line")
        svg.appendChild(line)

        const crosshair = document.createElementNS(SVG_NS, "line")
        crosshair.setAttribute("class", "chart-crosshair")
        crosshair.setAttribute("y1", padT); crosshair.setAttribute("y2", padT + innerH)
        crosshair.style.opacity = 0
        svg.appendChild(crosshair)

        const dot = document.createElementNS(SVG_NS, "circle")
        dot.setAttribute("r", 4.5); dot.setAttribute("class", "chart-hover-dot"); dot.style.opacity = 0
        svg.appendChild(dot)

        const overlay = document.createElementNS(SVG_NS, "rect")
        overlay.setAttribute("x", padL); overlay.setAttribute("y", padT)
        overlay.setAttribute("width", innerW); overlay.setAttribute("height", innerH)
        overlay.setAttribute("fill", "transparent")
        svg.appendChild(overlay)

        container.appendChild(svg)
        container.style.position = "relative"
        const tooltip = document.createElement("div")
        tooltip.className = "chart-tooltip"
        container.appendChild(tooltip)

        overlay.addEventListener("mousemove", (e) => {
            const rect = svg.getBoundingClientRect()
            const mx = (e.clientX - rect.left) * (w / rect.width)
            const idx = Math.max(0, Math.min(data.length - 1, Math.round((mx - padL) / innerW * (data.length - 1))))
            const d = data[idx]
            crosshair.setAttribute("x1", x(idx)); crosshair.setAttribute("x2", x(idx)); crosshair.style.opacity = 1
            dot.setAttribute("cx", x(idx)); dot.setAttribute("cy", y(d.value)); dot.style.opacity = 1
            tooltip.style.left = (x(idx) * (rect.width / w)) + "px"
            tooltip.style.top = (y(d.value) * (rect.height / h)) + "px"
            tooltip.style.opacity = 1
            tooltip.innerHTML = `${d.value.toLocaleString()} <span class="chart-tooltip__sub">· ${this.formatDateLabel(d.date)}</span>`
        })
        overlay.addEventListener("mouseleave", () => { crosshair.style.opacity = 0; dot.style.opacity = 0; tooltip.style.opacity = 0 })
    }

    // ---------- SVG bar chart with per-bar hover tooltip ----------
    renderBarChart(container, data) {
        container.innerHTML = ""
        const w = container.clientWidth || 400, h = 170
        const padL = 8, padR = 8, padT = 8, padB = 24
        const innerW = w - padL - padR, innerH = h - padT - padB
        const maxV = Math.max(...data.map((d) => d.value), 1) * 1.15
        const barGap = 10
        const barW = (innerW - barGap * (data.length - 1)) / data.length

        const svg = document.createElementNS(SVG_NS, "svg")
        svg.setAttribute("viewBox", `0 0 ${w} ${h}`)
        svg.setAttribute("width", "100%")
        svg.setAttribute("height", h)
        svg.style.display = "block"
        svg.style.overflow = "visible"

        const base = document.createElementNS(SVG_NS, "line")
        base.setAttribute("x1", padL); base.setAttribute("x2", w - padR)
        base.setAttribute("y1", padT + innerH); base.setAttribute("y2", padT + innerH)
        base.setAttribute("class", "chart-grid-line")
        svg.appendChild(base)

        container.style.position = "relative"
        const tooltip = document.createElement("div")
        tooltip.className = "chart-tooltip"

        data.forEach((d, i) => {
            const barH = Math.max((d.value / maxV) * innerH, 2)
            const bx = padL + i * (barW + barGap)
            const by = padT + innerH - barH
            const rect = document.createElementNS(SVG_NS, "rect")
            rect.setAttribute("x", bx); rect.setAttribute("y", by)
            rect.setAttribute("width", barW); rect.setAttribute("height", barH)
            rect.setAttribute("rx", 4)
            rect.setAttribute("class", "chart-bar")

            rect.addEventListener("mouseenter", () => rect.classList.add("chart-bar--hover"))
            rect.addEventListener("mousemove", () => {
                const rect2 = svg.getBoundingClientRect()
                tooltip.style.left = ((bx + barW / 2) * (rect2.width / w)) + "px"
                tooltip.style.top = (by * (rect2.height / h)) + "px"
                tooltip.style.opacity = 1
                tooltip.textContent = `${d.label}: ${d.value.toLocaleString()}`
            })
            rect.addEventListener("mouseleave", () => { rect.classList.remove("chart-bar--hover"); tooltip.style.opacity = 0 })
            svg.appendChild(rect)

            const label = document.createElementNS(SVG_NS, "text")
            label.setAttribute("x", bx + barW / 2); label.setAttribute("y", h - 6)
            label.setAttribute("text-anchor", "middle")
            label.setAttribute("class", "chart-axis-label")
            label.textContent = d.label
            svg.appendChild(label)
        })

        container.appendChild(svg)
        container.appendChild(tooltip)
    }
}
