import AOS from 'aos';

document.addEventListener('DOMContentLoaded', function() {
  AOS.init({
    startEvent: 'turbolinks:load', offset: 100, duration:700, easing:"ease-out-quad", once:!0
  });
	window.addEventListener('load', AOS.refresh);
  console.log("HHHHHHHHHERE")
});
