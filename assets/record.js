// Colours the stored record. The page carries the record as plain text, and
// this wraps each token in the class Rouge would have used (nl for a key, s2
// a string, mi an integer, mf a float, kc true/false/null, p punctuation), so
// rouge.css styles it the same as if it had been highlighted at build time,
// at a tenth of the bytes.
(() => {
  const code = document.querySelector("pre.highlight code");
  if (!code) return;
  const escape = (text) => text.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c]);
  const token = /("(?:[^"\\]|\\.)*")(\s*:)?|(-?\d+\.\d+(?:e[+-]?\d+)?)|(-?\d+)|(true|false|null)|([{}\[\],:])/g;
  code.innerHTML = code.textContent.replace(token, (match, string, colon, float, integer, constant, punctuation) => {
    if (string) return `<span class="${colon ? "nl" : "s2"}">${escape(string)}</span>${colon ? `<span class="p">${colon}</span>` : ""}`;
    if (float) return `<span class="mf">${float}</span>`;
    if (integer) return `<span class="mi">${integer}</span>`;
    if (constant) return `<span class="kc">${constant}</span>`;
    return `<span class="p">${punctuation}</span>`;
  });
})();
