$(function() {
    var renders = 0;
    var press_play = false;
    $(document).on({
        'shiny:value': function(event) {
            switch (event.name) {
                case 'year_range':
                    // WONT RESUME IF THE RENDER WAS DUE TO SOMETHING ELSE
                    if (renders > 0 && press_play) {
                        setTimeout(function() {
                            console.log('Animation Speed Changed!');
                            $('.slider-animate-button').click();
                        }, 200);

                        press_play = false;
                    } else {
                      renders = 1;
                    }
                    break;

                default:
            }
        }

    });


    Shiny.addCustomMessageHandler('resume', function(message) {
        press_play = true;
    });
});
