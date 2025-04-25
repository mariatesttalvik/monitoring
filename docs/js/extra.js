document.addEventListener('DOMContentLoaded', function() {
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    securityLevel: 'loose', // Adding this can help with some rendering issues
    flowchart: {
      useMaxWidth: true,
      htmlLabels: true
    }
  });
  
  // Log to verify the script is running
  console.log("Mermaid initialization script running");
  
  // Force re-initialization on theme switch or tab change
  var observer = new MutationObserver(function() {
    if (typeof mermaid !== 'undefined') {
      mermaid.init(undefined, document.querySelectorAll('.mermaid'));
      console.log("Mermaid re-initialized after DOM change");
    }
  });
  
  observer.observe(document.querySelector("body"), { 
    childList: true, 
    subtree: true 
  });
});