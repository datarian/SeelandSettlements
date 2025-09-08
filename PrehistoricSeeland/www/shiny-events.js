$(function() {
    var customAnimationInterval;
    var isCustomAnimating = false;
    var currentSpeed = 2000;
    
    // Handle animation speed updates from R
    Shiny.addCustomMessageHandler('update_animation_speed', function(message) {
        console.log('Speed update received:', message.speed);
        currentSpeed = message.speed;
        
        // If custom animation is running, restart with new speed
        if (isCustomAnimating) {
            stopCustomAnimation();
            startCustomAnimation();
        }
    });
    
    function startCustomAnimation() {
        console.log('Starting custom animation with speed:', currentSpeed);
        isCustomAnimating = true;
        
        // Hide manual controls when animating
        $('#manual_controls').hide();
        
        customAnimationInterval = setInterval(function() {
            var $slider = $('#year');
            if ($slider.length === 0) return;
            
            var current = parseInt($slider.val());
            var min = parseInt($slider.attr('data-min') || $slider.data('min'));
            var max = parseInt($slider.attr('data-max') || $slider.data('max'));
            
            // Calculate next year (loop back to min if at max)
            var next = (current >= max) ? min : current + 1;
            
            // Update slider value and trigger change event
            $slider.val(next);
            $slider.trigger('change');
            Shiny.setInputValue('year', next);
        }, currentSpeed);
    }
    
    function stopCustomAnimation() {
        console.log('Stopping custom animation');
        if (customAnimationInterval) {
            clearInterval(customAnimationInterval);
            customAnimationInterval = null;
        }
        isCustomAnimating = false;
        
        // Show manual controls when paused
        console.log('Showing manual controls');
        var $controls = $('#manual_controls');
        console.log('Controls element found:', $controls.length);
        $controls.show();
        $controls.css('display', 'flex');
    }
    
    // Override play/pause buttons when they appear
    $(document).on('click', '.slider-animate-button', function(e) {
        e.preventDefault();
        e.stopPropagation();
        
        var $button = $(this);
        var $playIcon = $button.find('.glyphicon-play');
        var $pauseIcon = $button.find('.glyphicon-pause');
        
        if (isCustomAnimating) {
            // Currently playing - pause
            stopCustomAnimation();
            $playIcon.show();
            $pauseIcon.hide();
        } else {
            // Currently paused - play
            startCustomAnimation();
            $playIcon.hide();
            $pauseIcon.show();
        }
        
        return false;
    });
    
    // Initialize button state when slider loads
    $(document).on('shiny:value', function(event) {
        if (event.name === 'year_range') {
            setTimeout(function() {
                var $button = $('.slider-animate-button');
                if ($button.length > 0) {
                    // Move play/pause button to our custom container
                    $button.detach().appendTo('#play_pause_container');
                    $button.addClass('control-btn');
                    
                    var $playIcon = $button.find('.glyphicon-play');
                    var $pauseIcon = $button.find('.glyphicon-pause');
                    
                    if (isCustomAnimating) {
                        $playIcon.hide();
                        $pauseIcon.show();
                        $('#manual_controls').hide();
                    } else {
                        $playIcon.show();
                        $pauseIcon.hide();
                        $('#manual_controls').show();
                        $('#manual_controls').css('display', 'flex');
                    }
                }
            }, 100);
        }
    });
});
