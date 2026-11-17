(function () {
  try {
    var p = window.location.pathname || '';
    var r = document.documentElement;
    if (p.indexOf('/merchant') === 0) {
      var t = localStorage.getItem('hoppa_merchant_theme');
      if (t === 'dark') {
        r.classList.add('dark');
      } else {
        r.classList.remove('dark');
      }
    } else {
      r.classList.remove('dark');
    }
  } catch (e) {}
})();
