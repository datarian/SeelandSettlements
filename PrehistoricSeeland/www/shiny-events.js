$(function() {
    var customAnimationInterval;
    var isCustomAnimating = false;
    var currentSpeed = 2000;
    var isDragging = false;
    var dragStart = { x: 0, y: 0 };
    var elementStart = { x: 0, y: 0 };
    
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
    
    // Make year display draggable and editable
    var $yearDisplay = $('#year_display');
    var $yearText = $('#current_year_display');
    var $yearInput = $('#year_input_container');
    
    // Click to edit functionality
    $yearText.on('click', function(e) {
        e.stopPropagation();
        if (!isDragging) {
            var currentYear = $(this).text();
            $('#year_jump_input').val(currentYear);
            $yearText.hide();
            $yearInput.show();
            setTimeout(function() {
                var input = document.getElementById('year_jump_input');
                input.focus();
                input.select();
            }, 50);
        }
    });
    
    // Handle Enter key and Escape key for year input
    $(document).on('keydown', '#year_jump_input', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            var value = $(this).val().trim();
            if (value !== '') {
                var numValue = parseFloat(value);
                if (!isNaN(numValue)) {
                    Shiny.setInputValue('year_jump_value', numValue, {priority: 'event'});
                }
            }
            $yearInput.hide();
            $yearText.show();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            $(this).val('');
            $yearInput.hide();
            $yearText.show();
        }
    });
    
    // Handle blur event for year input
    $(document).on('blur', '#year_jump_input', function() {
        var value = $(this).val().trim();
        if (value !== '' && value !== $('#current_year_display').text()) {
            var numValue = parseFloat(value);
            if (!isNaN(numValue)) {
                Shiny.setInputValue('year_jump_value', numValue, {priority: 'event'});
            }
        }
        setTimeout(function() {
            $yearInput.hide();
            $yearText.show();
        }, 100);
    });
    
    // Handle hide year input message from server
    Shiny.addCustomMessageHandler('hide_year_input', function(message) {
        $yearInput.hide();
        $yearText.show();
    });
    
    // Drag functionality
    $yearDisplay.on('mousedown', function(e) {
        if (e.target === $yearText[0]) {
            isDragging = false;
            dragStart = { x: e.clientX, y: e.clientY };
            elementStart = { 
                x: parseInt($yearDisplay.css('right')) || 10, 
                y: parseInt($yearDisplay.css('top')) || 10 
            };
            
            $(document).on('mousemove.yearDrag', function(e) {
                if (!isDragging) {
                    var distance = Math.sqrt(
                        Math.pow(e.clientX - dragStart.x, 2) + 
                        Math.pow(e.clientY - dragStart.y, 2)
                    );
                    if (distance > 5) {
                        isDragging = true;
                        $yearDisplay.addClass('dragging');
                    }
                }
                
                if (isDragging) {
                    var deltaX = dragStart.x - e.clientX;
                    var deltaY = e.clientY - dragStart.y;
                    
                    var newRight = Math.max(10, Math.min(window.innerWidth - 200, elementStart.x + deltaX));
                    var newTop = Math.max(10, Math.min(window.innerHeight - 100, elementStart.y + deltaY));
                    
                    $yearDisplay.css({
                        'right': newRight + 'px',
                        'top': newTop + 'px'
                    });
                }
            });
            
            $(document).on('mouseup.yearDrag', function() {
                $(document).off('.yearDrag');
                $yearDisplay.removeClass('dragging');
                setTimeout(function() {
                    isDragging = false;
                }, 100);
            });
        }
    });
    
    // Prevent text selection during drag
    $yearDisplay.on('selectstart', function() {
        return false;
    });
});
