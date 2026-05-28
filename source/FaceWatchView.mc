import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// =====================================================
// FaceWatchView
// -----------------------------------------------------
// V8 Sport Orbit Hours
// Numerales PNG 68x68 + manecillas procedurales de 3 colores
//
// OBJETIVOS DE ESTA VERSIÓN
// -----------------------------------------------------
// - Fondo procedural tipo fibra de carbono
// - AOD negro, sin fibra
// - Horas no lineales con PNGs
// - Marca propia en la parte superior
// - Manecillas de SOLO 3 colores:
//      1) gris obscuro
//      2) gris claro
//      3) blanco
// - Sin color accent en las manecillas
// - Puntas realmente afiladas
// - Sin deformación visual en la punta
// =====================================================

class FaceWatchView extends WatchUi.WatchFace {

    // =====================================================
    // REFRESH / SEGUNDERO
    // =====================================================

    const SWEEP_REFRESH_MS = 125;
    const SWEEP_STEPS_PER_SECOND = 8.0;

    // =====================================================
    // COLORES GENERALES
    // =====================================================

    const COLOR_BACKGROUND = 0x000000;

    const COLOR_CARBON_DARK   = 0x050505;
    const COLOR_CARBON_1      = 0x101010;
    const COLOR_CARBON_2      = 0x171717;
    const COLOR_CARBON_3      = 0x252525;
    const COLOR_CARBON_SHADOW = 0x030303;
    const COLOR_TRACK_DARK    = 0x202020;

    // =====================================================
    // COLORES DE MANECILLAS
    // -----------------------------------------------------
    // SOLO ESTOS 3
    // =====================================================

    const COLOR_HAND_DARK  = 0x5A5A5A;   // gris obscuro
    const COLOR_HAND_LIGHT = 0xCFCFCF;   // gris claro
    const COLOR_HAND_WHITE = 0xF5F5F5;   // blanco

    // =====================================================
    // FUENTE DE LA MARCA
    // -----------------------------------------------------
    // Opciones recomendadas:
    // - Graphics.FONT_XTINY
    // - Graphics.FONT_TINY
    // - Graphics.FONT_SMALL
    //
    // Mi recomendación actual:
    // - FONT_TINY
    // =====================================================

    const BRAND_FONT = Graphics.FONT_XTINY;

    // =====================================================
    // TAMAÑOS / PROPORCIONES
    // =====================================================

    const SCREEN_MARGIN = 0;
    const NUMERAL_ASSET_SIZE = 68;

    // -----------------------------------------------------
    // NÚMEROS MÁS PEGADOS AL BISEL
    // -----------------------------------------------------
    // Más grande = más afuera
    // Más pequeño = más al centro
    // -----------------------------------------------------
    const NUMBER_RADIUS_ACTIVE = 0.75;
    const NUMBER_RADIUS_AOD    = 0.72;

    // -----------------------------------------------------
    // TAMAÑO DE LA TRAMA DE CARBONO
    // -----------------------------------------------------
    const CARBON_TILE_ACTIVE = 22;
    const CARBON_TILE_AOD    = 28;

    // -----------------------------------------------------
    // POSICIÓN DE LA MARCA
    // -----------------------------------------------------
    // Más grande = más arriba
    // Más pequeño = más abajo
    // -----------------------------------------------------
    const LOGO_Y_FACTOR = 0.43;

    // =====================================================
    // ESTADO INTERNO
    // =====================================================

    var _isAwake;

    var _sweepTimer;
    var _timerRunning;

    var _baseSecondOfMinute;
    var _baseMinute;
    var _baseHour;
    var _baseTimerMs;
    var _numeralBitmaps;

    // =====================================================
    // CICLO DE VIDA
    // =====================================================

    function initialize() {
        WatchFace.initialize();

        _isAwake = true;

        _sweepTimer = null;
        _timerRunning = false;

        _baseSecondOfMinute = 0;
        _baseMinute = 0;
        _baseHour = 0;
        _baseTimerMs = 0;
        _numeralBitmaps = null;
    }

    function onLayout(dc) {
        // Todo se dibuja a mano.
    }

    function onShow() {
        _isAwake = true;
        loadNumeralBitmaps();
        resetSmoothTimeBase();
        startSweepTimer();
        WatchUi.requestUpdate();
    }

    function onHide() {
        stopSweepTimer();
    }

    function onExitSleep() {
        _isAwake = true;
        resetSmoothTimeBase();
        startSweepTimer();
        WatchUi.requestUpdate();
    }

    function onEnterSleep() {
        _isAwake = false;
        stopSweepTimer();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        drawWatchFace(dc);
    }

    // =====================================================
    // TIMER
    // =====================================================

    function startSweepTimer() {
        if (_sweepTimer == null) {
            _sweepTimer = new Timer.Timer();
        }

        if (!_timerRunning) {
            _sweepTimer.start(method(:onSweepTick), SWEEP_REFRESH_MS, true);
            _timerRunning = true;
        }
    }

    function stopSweepTimer() {
        if ((_sweepTimer != null) && _timerRunning) {
            _sweepTimer.stop();
            _timerRunning = false;
        }
    }

    function onSweepTick() {
        if (_isAwake) {
            WatchUi.requestUpdate();
        }
    }

    // =====================================================
    // SETTINGS
    // =====================================================

    function getBrandName() {
        var text = "LUIS VENEGAS";
        var value = Application.Properties.getValue("BrandName");

        if (value != null) {
            var tmp = value.toString();

            if (tmp.length() > 0) {
                text = tmp;
            }
        }

        return text;
    }

    function getAccentTheme() {
        var theme = 0;
        var value = Application.Properties.getValue("AccentTheme");

        if (value != null) {
            theme = value.toNumber();
        }

        return theme;
    }

    // -----------------------------------------------------
    // Logo configurable
    // -----------------------------------------------------
    // Si después quieres que la marca NO cambie de color,
    // puedes regresar aquí un color fijo como:
    // return COLOR_HAND_WHITE;
    // -----------------------------------------------------
    function getLogoColor() {
        var theme = getAccentTheme();
        var color = 0xA7D7E8;

        if (theme == 1) {
            color = 0xFF2A2A;
        } else if (theme == 2) {
            color = 0xD6B15E;
        } else if (theme == 3) {
            color = 0x66D17A;
        } else if (theme == 4) {
            color = 0xFFFFFF;
        }

        return color;
    }

    // =====================================================
    // TIEMPO / MATEMÁTICAS
    // =====================================================

    function resetSmoothTimeBase() {
        var clock = System.getClockTime();

        _baseHour = clock.hour;
        _baseMinute = clock.min;
        _baseSecondOfMinute = clock.sec;
        _baseTimerMs = System.getTimer();
    }

    function getTotalSmoothSeconds() {
        var elapsedMs = System.getTimer() - _baseTimerMs;

        if (elapsedMs < 0) {
            elapsedMs = 0;
        }

        var elapsedSeconds = elapsedMs / 1000.0;

        var totalSeconds =
            (_baseHour * 3600.0) +
            (_baseMinute * 60.0) +
            _baseSecondOfMinute +
            elapsedSeconds;

        return totalSeconds;
    }

    function wrapFloat(value, maxValue) {
        var cycles = (value / maxValue).toNumber();
        return value - (cycles * maxValue);
    }

    function roundToNumber(value) {
        return (value + 0.5).toNumber();
    }

    // =====================================================
    // DIBUJO PRINCIPAL
    // =====================================================

    function drawWatchFace(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var cx = (width / 2).toNumber();
        var cy = (height / 2).toNumber();

        var size = width;
        if (height < width) {
            size = height;
        }

        var radius = ((size / 2) - SCREEN_MARGIN).toNumber();

        if (_isAwake) {
            drawActiveBackground(dc, width, height, cx, cy, radius);
        } else {
            drawAodBackground(dc, width, height);
        }

        var clock = System.getClockTime();

        if (_isAwake) {
            drawSportTrack(dc, cx, cy, radius);
        }

        drawOrbitalNumbers(dc, cx, cy, radius, clock);

        if (_isAwake) {
            drawBrandMark(dc, cx, cy, radius);
            drawDataWidgets(dc, cx, cy, radius);
        }

        drawHands(dc, cx, cy, radius, clock);
        drawCenterCap(dc, cx, cy);
    }

    // =====================================================
    // FONDOS
    // =====================================================

    function drawActiveBackground(dc, width, height, cx, cy, radius) {
        dc.setColor(COLOR_CARBON_DARK, COLOR_CARBON_DARK);
        dc.fillRectangle(0, 0, width, height);

        drawCarbonWeave(dc, width, height, cx, cy, radius, true);
        drawOuterFillSafety(dc, cx, cy, radius);
    }

    function drawAodBackground(dc, width, height) {
        dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
        dc.fillRectangle(0, 0, width, height);
    }

    function drawSportTrack(dc, cx, cy, radius) {
        dc.setColor(COLOR_TRACK_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, roundToNumber(radius * 0.88));

        dc.setColor(COLOR_TRACK_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, roundToNumber(radius * 0.67));

        for (var i = 0; i < 60; i += 1) {
            var angleRad = Math.toRadians((i * 6) - 90);
            var ux = Math.cos(angleRad);
            var uy = Math.sin(angleRad);

            var outer = radius * 0.96;
            var inner;

            if ((i % 5) == 0) {
                inner = radius * 0.925;
                dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
            } else {
                inner = radius * 0.945;
                dc.setColor(COLOR_TRACK_DARK, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
            }

            dc.drawLine(
                roundToNumber(cx + ux * inner),
                roundToNumber(cy + uy * inner),
                roundToNumber(cx + ux * outer),
                roundToNumber(cy + uy * outer)
            );
        }
    }

    function drawOuterFillSafety(dc, cx, cy, radius) {
        dc.setColor(COLOR_CARBON_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, radius + 1);
    }

    // =====================================================
    // FIBRA DE CARBONO PROCEDURAL
    // =====================================================

    function drawCarbonWeave(dc, width, height, cx, cy, radius, fullDetail) {
        var tile;

        if (fullDetail) {
            tile = CARBON_TILE_ACTIVE;
        } else {
            tile = CARBON_TILE_AOD;
        }

        var rows = (height / tile).toNumber() + 4;
        var cols = (width / tile).toNumber() + 4;

        for (var row = 0; row < rows; row += 1) {
            for (var col = 0; col < cols; col += 1) {
                var x = (col * tile) - (tile * 2);
                var y = (row * tile) - (tile * 2);

                var horizontal = ((row + col) % 2) == 0;
                drawCarbonTile(dc, x, y, tile, horizontal, fullDetail);
            }
        }

        drawEdgeFade(dc, cx, cy, radius);
    }

    function drawCarbonTile(dc, x, y, tile, horizontal, fullDetail) {
        if (horizontal) {
            drawHorizontalCarbonTile(dc, x, y, tile, fullDetail);
        } else {
            drawVerticalCarbonTile(dc, x, y, tile, fullDetail);
        }
    }

    function drawHorizontalCarbonTile(dc, x, y, tile, fullDetail) {
        dc.setColor(COLOR_CARBON_2, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, tile, tile);

        dc.setColor(COLOR_CARBON_3, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + 2, tile, 2);

        dc.setColor(COLOR_CARBON_1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + (tile / 2).toNumber(), tile, 1);

        if (fullDetail) {
            dc.setColor(COLOR_CARBON_SHADOW, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y + tile - 3, tile, 1);
        }
    }

    function drawVerticalCarbonTile(dc, x, y, tile, fullDetail) {
        dc.setColor(COLOR_CARBON_1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, tile, tile);

        dc.setColor(COLOR_CARBON_3, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y, 2, tile);

        dc.setColor(COLOR_CARBON_2, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + (tile / 2).toNumber(), y, 1, tile);

        if (fullDetail) {
            dc.setColor(COLOR_CARBON_SHADOW, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + tile - 3, y, 1, tile);
        }
    }

    function drawEdgeFade(dc, cx, cy, radius) {
        dc.setColor(0x090909, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, radius - 1);

        dc.setColor(0x020202, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, radius + 1);
    }

    // =====================================================
    // MARCA
    // =====================================================

    function drawBrandMark(dc, cx, cy, radius) {
        var logoText = getBrandName();

        // -------------------------------------------------
        // AJUSTE FÁCIL DEL LOGO:
        // - aumenta LOGO_Y_FACTOR para subirlo
        // - o suma/resta manualmente aquí:
        //
        // ejemplo:
        // var logoY = roundToNumber(cy - (radius * LOGO_Y_FACTOR)) - 3;
        //
        // negativo = más arriba
        // positivo = más abajo
        // -------------------------------------------------
        var logoY = roundToNumber(cy - (radius * LOGO_Y_FACTOR));

        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx + 1,
            logoY + 1,
            BRAND_FONT,
            logoText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            logoY,
            BRAND_FONT,
            logoText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // =====================================================
    // CRAZY HOURS - NÚMEROS PNG
    // =====================================================

    function drawOrbitalNumbers(dc, cx, cy, radius, clock) {
        var currentHour = clock.hour % 12;
        if (currentHour == 0) {
            currentHour = 12;
        }

        var nextHour = currentHour + 1;
        if (nextHour > 12) {
            nextHour = 1;
        }

        for (var position = 0; position < 12; position += 1) {
            var hourLabel = getHourForPosition(position);

            // En AOD solo se ven la hora actual y la siguiente
            if (!_isAwake) {
                if ((hourLabel != currentHour) && (hourLabel != nextHour)) {
                    continue;
                }
            }

            drawOneNumber(dc, cx, cy, radius, position, hourLabel);
        }
    }

    function drawOneNumber(dc, cx, cy, radius, position, hourLabel) {
        var textRadius;

        if (_isAwake) {
            textRadius = radius * NUMBER_RADIUS_ACTIVE;
        } else {
            textRadius = radius * NUMBER_RADIUS_AOD;
        }

        var angleDeg = position * 30;
        var angleRad = Math.toRadians(angleDeg - 90);

        var centerX = roundToNumber(cx + Math.cos(angleRad) * textRadius);
        var centerY = roundToNumber(cy + Math.sin(angleRad) * textRadius);

        // -------------------------------------------------
        // AJUSTE FINO DE NÚMEROS
        // -------------------------------------------------
        centerX = centerX + getNumberXOffset(position);
        centerY = centerY + getNumberYOffset(position);

        drawNumberHalo(dc, centerX, centerY, hourLabel);

        var bitmap = getNumeralBitmap(hourLabel);

        var drawX = centerX - (NUMERAL_ASSET_SIZE / 2).toNumber();
        var drawY = centerY - (NUMERAL_ASSET_SIZE / 2).toNumber();

        dc.drawBitmap(drawX, drawY, bitmap);
    }

    // =====================================================
    // WIDGETS DEPORTIVOS
    // =====================================================

    function drawDataWidgets(dc, cx, cy, radius) {
        var widgetY = roundToNumber(cy + (radius * 0.28));
        var text = getStepText() + " | " + getBatteryText();

        dc.setColor(COLOR_TRACK_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(cx - 30, widgetY - 7, cx + 30, widgetY - 7);

        dc.setColor(getLogoColor(), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(cx - 28, widgetY - 7, cx - 14, widgetY - 7);

        dc.setColor(0x8A929C, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            widgetY,
            Graphics.FONT_XTINY,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function getStepText() {
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();

            if ((info != null) && (info.steps != null)) {
                var steps = info.steps;

                if (steps >= 1000) {
                    return (steps / 1000).toNumber().toString() + "K";
                }

                return steps.toString();
            }
        }

        return "--";
    }

    function getBatteryText() {
        var stats = System.getSystemStats();
        var battery = stats.battery.toNumber();
        return battery.toString() + "%";
    }

    function drawNumberHalo(dc, centerX, centerY, hourLabel) {
        if (!_isAwake) {
            return;
        }

        var clock = System.getClockTime();
        var currentHour = clock.hour % 12;

        if (currentHour == 0) {
            currentHour = 12;
        }

        if (hourLabel == currentHour) {
            dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(centerX, centerY, 34);

            dc.setColor(getLogoColor(), Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawCircle(centerX, centerY, 35);
        }
    }

    function loadNumeralBitmaps() {
        if (_numeralBitmaps != null) {
            return;
        }

        _numeralBitmaps = [
            WatchUi.loadResource(Rez.Drawables.Num1),
            WatchUi.loadResource(Rez.Drawables.Num2),
            WatchUi.loadResource(Rez.Drawables.Num3),
            WatchUi.loadResource(Rez.Drawables.Num4),
            WatchUi.loadResource(Rez.Drawables.Num5),
            WatchUi.loadResource(Rez.Drawables.Num6),
            WatchUi.loadResource(Rez.Drawables.Num7),
            WatchUi.loadResource(Rez.Drawables.Num8),
            WatchUi.loadResource(Rez.Drawables.Num9),
            WatchUi.loadResource(Rez.Drawables.Num10),
            WatchUi.loadResource(Rez.Drawables.Num11),
            WatchUi.loadResource(Rez.Drawables.Num12)
        ];
    }

    function getNumeralBitmap(hourLabel) {
        loadNumeralBitmaps();
        var bitmaps = _numeralBitmaps as Lang.Array;
        return bitmaps[hourLabel - 1];
    }

    // =====================================================
    // OFFSETS DE NÚMEROS
    // =====================================================

    function getNumberXOffset(position) {
        if (position == 0)  { return 0;  }   // 12
        if (position == 1)  { return 0;  }   // 8
        if (position == 2)  { return 2;  }   // 4
        if (position == 3)  { return -4; }   // 1
        if (position == 4)  { return -4; }   // 9
        if (position == 5)  { return -2; }   // 5
        if (position == 6)  { return 0;  }   // 11
        if (position == 7)  { return 2;  }   // 7
        if (position == 8)  { return 3;  }   // 3
        if (position == 9)  { return 4;  }   // 10
        if (position == 10) { return 2;  }   // 6

        return 0; // 2
    }

    function getNumberYOffset(position) {
        if (position == 0)  { return 10;  }  // 12
        if (position == 1)  { return 10;  }  // 8
        if (position == 2)  { return 6;   }  // 4
        if (position == 3)  { return 0;   }  // 1
        if (position == 4)  { return -4;  }  // 9
        if (position == 5)  { return -4;  }  // 5
        if (position == 6)  { return -10; }  // 11
        if (position == 7)  { return -6;  }  // 7
        if (position == 8)  { return -4;  }  // 3
        if (position == 9)  { return 0;   }  // 10
        if (position == 10) { return 6;   }  // 6

        return 10; // 2
    }

    // =====================================================
    // MAPEO CRAZY HOURS
    // =====================================================

    function getHourForPosition(position) {
        if (position == 0) {
            return 12;
        } else if (position == 1) {
            return 8;
        } else if (position == 2) {
            return 4;
        } else if (position == 3) {
            return 1;
        } else if (position == 4) {
            return 9;
        } else if (position == 5) {
            return 5;
        } else if (position == 6) {
            return 11;
        } else if (position == 7) {
            return 7;
        } else if (position == 8) {
            return 3;
        } else if (position == 9) {
            return 10;
        } else if (position == 10) {
            return 6;
        } else {
            return 2;
        }
    }

    function getOrbitalHourAngle(hour12) {
        var angle = 330;

        if (hour12 == 12) {
            angle = 0;
        } else if (hour12 == 8) {
            angle = 30;
        } else if (hour12 == 4) {
            angle = 60;
        } else if (hour12 == 1) {
            angle = 90;
        } else if (hour12 == 9) {
            angle = 120;
        } else if (hour12 == 5) {
            angle = 150;
        } else if (hour12 == 11) {
            angle = 180;
        } else if (hour12 == 7) {
            angle = 210;
        } else if (hour12 == 3) {
            angle = 240;
        } else if (hour12 == 10) {
            angle = 270;
        } else if (hour12 == 6) {
            angle = 300;
        }

        return angle;
    }

    // =====================================================
    // MANECILLAS
    // -----------------------------------------------------
    // PRINCIPIO DE ESTA VERSIÓN:
    // - solo 3 colores
    // - puntas afiladas
    // - sin remates de color
    // - sin deformar la punta con líneas gruesas rectas
    //
    // Para evitar puntas "cuadradas":
    // la punta se dibuja con una pequeña rutina
    // que va estrechando la forma progresivamente.
    // =====================================================

    function drawHands(dc, cx, cy, radius, clock) {
        var hour12 = clock.hour % 12;

        if (hour12 == 0) {
            hour12 = 12;
        }

        var hourAngle = getOrbitalHourAngle(hour12);

        var minuteAngle;
        var secondAngle;

        if (_isAwake) {
            var totalSeconds = getTotalSmoothSeconds();

            var rawSecond = wrapFloat(totalSeconds, 60.0);
            var steppedSecond =
                ((rawSecond * SWEEP_STEPS_PER_SECOND).toNumber()) /
                SWEEP_STEPS_PER_SECOND;

            var smoothMinute = wrapFloat(totalSeconds / 60.0, 60.0);

            secondAngle = steppedSecond * 6.0;
            minuteAngle = smoothMinute * 6.0;
        } else {
            secondAngle = 0;
            minuteAngle = clock.min * 6.0;
        }

        drawHourHand(dc, cx, cy, radius, hourAngle);
        drawMinuteHand(dc, cx, cy, radius, minuteAngle);

        if (_isAwake) {
            drawSecondHand(dc, cx, cy, radius, secondAngle);
        }
    }

    function drawHourHand(dc, cx, cy, radius, angleDeg) {
        // -------------------------------------------------
        // AJUSTE DE MANECILLA DE HORA
        //
        // length      = largo total
        // tail        = cola detrás del centro
        // outerWidth  = grosor total
        // hollowWidth = hueco interior
        // tipStart    = punto donde empieza la punta
        //
        // Si quieres más robusta:
        // - sube outerWidth
        // Si la quieres más corta:
        // - baja length
        // -------------------------------------------------
        drawDescentStyleHand(
            dc,
            cx,
            cy,
            angleDeg,
            radius * 0.33,
            radius * 0.04,
            14,
            6,
            0.69
        );
    }

    function drawMinuteHand(dc, cx, cy, radius, angleDeg) {
        drawDescentStyleHand(
            dc,
            cx,
            cy,
            angleDeg,
            radius * 0.55,
            radius * 0.05,
            12,
            5,
            0.72
        );
    }

    function drawSecondHand(dc, cx, cy, radius, angleDeg) {
        var angleRad = Math.toRadians(angleDeg - 90);

        var ux = Math.cos(angleRad);
        var uy = Math.sin(angleRad);
        var nx = -uy;
        var ny = ux;

        var tipX = roundToNumber(cx + ux * (radius * 0.78));
        var tipY = roundToNumber(cy + uy * (radius * 0.78));

        var tailX = roundToNumber(cx - ux * (radius * 0.18));
        var tailY = roundToNumber(cy - uy * (radius * 0.18));

        // línea principal del segundero
        dc.setColor(COLOR_HAND_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(tailX, tailY, tipX, tipY);

        // contrapeso rectangular sin círculo
        var counterStartCx = cx - ux * (radius * 0.24);
        var counterStartCy = cy - uy * (radius * 0.24);

        var counterEndCx = cx - ux * (radius * 0.34);
        var counterEndCy = cy - uy * (radius * 0.34);

        var halfW = 3;

        var x1 = roundToNumber(counterStartCx - nx * halfW);
        var y1 = roundToNumber(counterStartCy - ny * halfW);

        var x2 = roundToNumber(counterStartCx + nx * halfW);
        var y2 = roundToNumber(counterStartCy + ny * halfW);

        var x3 = roundToNumber(counterEndCx + nx * halfW);
        var y3 = roundToNumber(counterEndCy + ny * halfW);

        var x4 = roundToNumber(counterEndCx - nx * halfW);
        var y4 = roundToNumber(counterEndCy - ny * halfW);

        // borde del contrapeso
        dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(x1, y1, x2, y2);
        dc.drawLine(x2, y2, x3, y3);
        dc.drawLine(x3, y3, x4, y4);
        dc.drawLine(x4, y4, x1, y1);

        // relleno visual del contrapeso con líneas
        for (var i = -2; i <= 2; i += 1) {
            var sx = roundToNumber(counterStartCx + nx * i);
            var sy = roundToNumber(counterStartCy + ny * i);
            var ex = roundToNumber(counterEndCx + nx * i);
            var ey = roundToNumber(counterEndCy + ny * i);

            dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(sx, sy, ex, ey);
        }
    }

    // =====================================================
    // MANECILLA ESTILO DESCENT
    // -----------------------------------------------------
    // Esta función hace:
    // 1) cuerpo principal
    // 2) hueco interior
    // 3) puente transversal
    // 4) punta afilada progresiva
    //
    // SOLO usa 3 colores:
    // - COLOR_HAND_DARK
    // - COLOR_HAND_LIGHT
    // - COLOR_HAND_WHITE
    // =====================================================

    function drawDescentStyleHand(dc, cx, cy, angleDeg, length, tail, outerWidth, hollowWidth, tipStartFactor) {
        var angleRad = Math.toRadians(angleDeg - 90);

        var ux = Math.cos(angleRad);
        var uy = Math.sin(angleRad);

        var nx = -uy;
        var ny = ux;

        var tailX = roundToNumber(cx - ux * tail);
        var tailY = roundToNumber(cy - uy * tail);

        var bodyEndDist = length * tipStartFactor;
        var bodyEndX = roundToNumber(cx + ux * bodyEndDist);
        var bodyEndY = roundToNumber(cy + uy * bodyEndDist);

        var tipX = roundToNumber(cx + ux * length);
        var tipY = roundToNumber(cy + uy * length);

        // -------------------------------------------------
        // 1) CONTORNO / CUERPO EXTERIOR
        // -------------------------------------------------
        dc.setColor(COLOR_HAND_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(outerWidth);
        dc.drawLine(tailX, tailY, bodyEndX, bodyEndY);

        // -------------------------------------------------
        // 2) CUERPO INTERIOR
        // -------------------------------------------------
        dc.setColor(COLOR_HAND_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(outerWidth - 3);
        dc.drawLine(tailX, tailY, bodyEndX, bodyEndY);

        // -------------------------------------------------
        // 3) BANDA CENTRAL EN GRIS CLARO
        // -------------------------------------------------
        dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(outerWidth - 7);
        dc.drawLine(tailX, tailY, bodyEndX, bodyEndY);

        // -------------------------------------------------
        // 4) HUECO INTERIOR
        // -------------------------------------------------
        var hollowStartDist = length * 0.19;
        var hollowEndDist = length * 0.59;

        var hollowStartX = roundToNumber(cx + ux * hollowStartDist);
        var hollowStartY = roundToNumber(cy + uy * hollowStartDist);

        var hollowEndX = roundToNumber(cx + ux * hollowEndDist);
        var hollowEndY = roundToNumber(cy + uy * hollowEndDist);

        dc.setColor(COLOR_HAND_DARK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(hollowWidth);
        dc.drawLine(hollowStartX, hollowStartY, hollowEndX, hollowEndY);

        // -------------------------------------------------
        // 5) PUENTE TRANSVERSAL
        // -------------------------------------------------
        var bridgeDist = length * 0.43;
        var bridgeCx = roundToNumber(cx + ux * bridgeDist);
        var bridgeCy = roundToNumber(cy + uy * bridgeDist);

        var bridgeHalf = (outerWidth / 2).toNumber();

        var bridgeX1 = roundToNumber(bridgeCx - nx * bridgeHalf);
        var bridgeY1 = roundToNumber(bridgeCy - ny * bridgeHalf);

        var bridgeX2 = roundToNumber(bridgeCx + nx * bridgeHalf);
        var bridgeY2 = roundToNumber(bridgeCy + ny * bridgeHalf);

        dc.setColor(COLOR_HAND_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(bridgeX1, bridgeY1, bridgeX2, bridgeY2);

        // -------------------------------------------------
        // 6) PUNTA AFILADA
        // -------------------------------------------------
        // Se dibuja progresivamente para NO terminar
        // en un cuadrado grueso.
        // -------------------------------------------------
        drawTaperedTip(
            dc,
            bodyEndX,
            bodyEndY,
            tipX,
            tipY,
            (outerWidth / 2).toNumber(),
            COLOR_HAND_DARK,
            COLOR_HAND_WHITE,
            COLOR_HAND_LIGHT
        );
    }

    // =====================================================
    // PUNTA AFILADA
    // -----------------------------------------------------
    // Dibuja la punta en pequeñas franjas, estrechándose
    // poco a poco hasta llegar a cero.
    // Así evitamos una punta cuadrada.
    // =====================================================

    function drawTaperedTip(dc, baseCx, baseCy, tipX, tipY, baseHalfWidth, outerColor, fillColor, highlightColor) {
        var dx = tipX - baseCx;
        var dy = tipY - baseCy;

        var len = Math.sqrt((dx * dx) + (dy * dy));

        if (len <= 0) {
            return;
        }

        var ux = dx / len;
        var uy = dy / len;

        var nx = -uy;
        var ny = ux;

        var steps = len.toNumber();
        if (steps < 1) {
            steps = 1;
        }

        for (var i = 0; i <= steps; i += 1) {
            var t = i / steps;

            var cxLine = baseCx + (dx * t);
            var cyLine = baseCy + (dy * t);

            var halfOuter = baseHalfWidth * (1.0 - t);
            var halfInner = (baseHalfWidth - 1.5) * (1.0 - t);
            var halfHighlight = (baseHalfWidth - 3.0) * (1.0 - t);

            if (halfOuter < 0) {
                halfOuter = 0;
            }
            if (halfInner < 0) {
                halfInner = 0;
            }
            if (halfHighlight < 0) {
                halfHighlight = 0;
            }

            // borde exterior oscuro
            var ox1 = roundToNumber(cxLine - nx * halfOuter);
            var oy1 = roundToNumber(cyLine - ny * halfOuter);
            var ox2 = roundToNumber(cxLine + nx * halfOuter);
            var oy2 = roundToNumber(cyLine + ny * halfOuter);

            dc.setColor(outerColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(ox1, oy1, ox2, oy2);

            // relleno blanco
            var ix1 = roundToNumber(cxLine - nx * halfInner);
            var iy1 = roundToNumber(cyLine - ny * halfInner);
            var ix2 = roundToNumber(cxLine + nx * halfInner);
            var iy2 = roundToNumber(cyLine + ny * halfInner);

            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(ix1, iy1, ix2, iy2);

            // pequeño highlight central gris claro
            var hx1 = roundToNumber(cxLine - nx * halfHighlight);
            var hy1 = roundToNumber(cyLine - ny * halfHighlight);
            var hx2 = roundToNumber(cxLine + nx * halfHighlight);
            var hy2 = roundToNumber(cyLine + ny * halfHighlight);

            dc.setColor(highlightColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(hx1, hy1, hx2, hy2);
        }
    }

    // =====================================================
    // CENTRO
    // =====================================================

    function drawCenterCap(dc, cx, cy) {
        dc.setColor(COLOR_HAND_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 10);

        dc.setColor(getLogoColor(), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, 11);

        dc.setColor(COLOR_HAND_DARK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 8);

        dc.setColor(COLOR_HAND_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 6);

        dc.setColor(COLOR_HAND_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 3);

        dc.setColor(COLOR_HAND_DARK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 1);
    }
}
