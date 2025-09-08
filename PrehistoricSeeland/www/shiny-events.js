$(function() {
    var customAnimationInterval;
    var isCustomAnimating = false;
    var currentSpeed = 2000;
    
    // Function to immediately update slider visual display
    function updateSliderDisplay($slider, value) {
        // Update the input value
        $slider.val(value);
        $slider.trigger('change');
        
        // Force update the ionRangeSlider display if it exists
        var sliderInstance = $slider.data("ionRangeSlider");
        if (sliderInstance) {
            sliderInstance.update({
                from: value
            });
        }
    }
    
    // Handle animation speed updates from R
    Shiny.addCustomMessageHandler('update_animation_speed', function(message) {
        currentSpeed = message.speed;
        
        // If custom animation is running, restart with new speed
        if (isCustomAnimating) {
            stopCustomAnimation();
            startCustomAnimation();
        }
    });
    
    function startCustomAnimation() {
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
            
            // Update slider value and visual display immediately
            updateSliderDisplay($slider, next);
            Shiny.setInputValue('year', next);
        }, currentSpeed);
    }
    
    function stopCustomAnimation() {
        if (customAnimationInterval) {
            clearInterval(customAnimationInterval);
            customAnimationInterval = null;
        }
        isCustomAnimating = false;
        
        // Show manual controls when paused
        var $controls = $('#manual_controls');
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
    
    // Handle manual navigation buttons for immediate visual feedback
    $(document).on('click', '#year_forward', function() {
        var $slider = $('#year');
        if ($slider.length > 0) {
            var current = parseInt($slider.val());
            var min = parseInt($slider.attr('data-min') || $slider.data('min'));
            var max = parseInt($slider.attr('data-max') || $slider.data('max'));
            var next = (current >= max) ? min : current + 1;
            
            // Update display immediately
            updateSliderDisplay($slider, next);
        }
    });
    
    $(document).on('click', '#year_back', function() {
        var $slider = $('#year');
        if ($slider.length > 0) {
            var current = parseInt($slider.val());
            var min = parseInt($slider.attr('data-min') || $slider.data('min'));
            var max = parseInt($slider.attr('data-max') || $slider.data('max'));
            var next = (current <= min) ? max : current - 1;
            
            // Update display immediately
            updateSliderDisplay($slider, next);
        }
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
