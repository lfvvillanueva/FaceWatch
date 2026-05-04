import Toybox.Graphics;
import Toybox.WatchUi;

// =====================================================
// Background
// -----------------------------------------------------
// Este archivo viene del template "Simple with Settings".
// En nuestra versión actual casi no se usa, porque estamos
// dibujando toda la carátula manualmente desde FaceWatchView.mc.
//
// Lo dejamos limpio para evitar warnings innecesarios.
// =====================================================

class Background extends WatchUi.Drawable {

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);
    }

    function draw(dc as Dc) as Void {
        // Fondo negro básico.
        // En FaceWatchView.mc también limpiamos la pantalla,
        // así que este fondo es solo una base segura.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}