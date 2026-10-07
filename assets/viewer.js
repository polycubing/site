// The shape viewer. Reads the page's layers (each a list of copies, each a
// list of unit cells with a ring number), builds one surface per copy from
// its exposed faces, outlines creases only, and draws it all with plain
// WebGL: one shader pair, a depth buffer, an orbit camera. Nothing more is
// needed for axis-aligned cubes.
(() => {
  const page = JSON.parse(document.getElementById("page").textContent);
  const container = document.getElementById("viewer");
  if (!container || !page.layers.length) return;

  // Census coordinates have z up. The screen has y up.
  const seed = page.layers[0].copies[0].cells;
  const center = [0, 1, 2].map(axis => (Math.min(...seed.map(c => c[axis])) + Math.max(...seed.map(c => c[axis])) + 1) / 2);
  const place = ([x, y, z]) => [x + 0.5 - center[0], z + 0.5 - center[2], -(y + 0.5 - center[1])];
  const orient = ([x, y, z]) => [x, z, -y];

  const directions = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]];
  const add = (a, b) => a.map((c, i) => c + b[i]);
  const key = (cell) => cell.join(",");

  // The four corners of a cell's face in a direction, counter-clockwise seen
  // from outside, and the in-plane directions its edges border on.
  const face = (direction) => {
    const axis = direction.findIndex(d => d !== 0);
    const sign = direction[axis];
    const u = [0, 0, 0], v = [0, 0, 0];
    u[(axis + 1) % 3] = 1; v[(axis + 2) % 3] = 1;
    const base = [-0.5, -0.5, -0.5]; base[axis] = sign * 0.5;
    const corner = (a, b) => base.map((c, i) => c + a * u[i] + b * v[i]);
    const quad = [corner(0, 0), corner(1, 0), corner(1, 1), corner(0, 1)];
    return { quad: sign > 0 ? quad : quad.reverse(), sides: [u, u.map(c => -c), v, v.map(c => -c)] };
  };

  // Triangles and crease edges for one copy. An edge is skipped where the
  // neighbouring cell across it has the same face exposed, since the two
  // faces are one flat surface there.
  const surface = (cells, color) => {
    const occupied = new Set(cells.map(key));
    const triangles = [], edges = [];
    for (const cell of cells) {
      for (const direction of directions) {
        if (occupied.has(key(add(cell, direction)))) continue;
        const { quad, sides } = face(direction);
        const corners = quad.map(corner => place(cell).map((c, i) => c + orient(corner)[i]));
        const normal = orient(direction);
        for (const index of [0, 1, 2, 0, 2, 3]) triangles.push(...corners[index], ...normal, ...color);
        for (const side of sides) {
          const flat = occupied.has(key(add(cell, side))) && !occupied.has(key(add(add(cell, side), direction)));
          if (flat) continue;
          const along = quad.filter(corner => side.every((s, i) => s === 0 || Math.sign(corner[i]) === Math.sign(s)));
          for (const corner of along) edges.push(...place(cell).map((c, i) => c + orient(corner)[i]), 0, 0, 0, 0.1, 0.1, 0.1);
        }
      }
    }
    return { triangles, edges };
  };

  const hsl = (h, s, l) => {
    const f = (n) => { const k = (n + h * 12) % 12; const a = s * Math.min(l, 1 - l); return l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)); };
    return [f(0), f(8), f(4)];
  };
  // The seed is grey. Each ring out is lighter, and copies within a ring are
  // told apart by hue.
  const tint = (ring, index) => ring === 0 ? hsl(0, 0, 0.74) : hsl((index * 0.618) % 1, 0.25, [0, 0.54, 0.84, 0.66, 0.9][ring] ?? 0.7);

  const canvas = document.createElement("canvas");
  container.appendChild(canvas);
  const gl = canvas.getContext("webgl", { antialias: true, alpha: true });
  if (!gl) { container.textContent = "This browser has no WebGL, so no viewer. The downloads still work."; return; }

  const compile = (type, source) => { const s = gl.createShader(type); gl.shaderSource(s, source); gl.compileShader(s); return s; };
  const program = gl.createProgram();
  gl.attachShader(program, compile(gl.VERTEX_SHADER, `
    attribute vec3 position; attribute vec3 normal; attribute vec3 color;
    uniform mat4 matrix; uniform float lit;
    varying vec3 shade;
    void main() {
      vec3 n = normalize(normal);
      float light = 0.42 + 0.5 * max(dot(n, normalize(vec3(-0.45, 0.75, 0.6))), 0.0) + 0.18 * max(dot(n, normalize(vec3(0.6, -0.3, -0.5))), 0.0);
      shade = mix(color, color * min(light, 1.0), lit);
      gl_Position = matrix * vec4(position, 1.0);
    }`));
  gl.attachShader(program, compile(gl.FRAGMENT_SHADER, `
    precision mediump float; varying vec3 shade;
    void main() { gl_FragColor = vec4(shade, 1.0); }`));
  gl.linkProgram(program);
  gl.useProgram(program);
  const attribute = (name) => { const a = gl.getAttribLocation(program, name); gl.enableVertexAttribArray(a); return a; };
  const attributes = { position: attribute("position"), normal: attribute("normal"), color: attribute("color") };
  const uniforms = { matrix: gl.getUniformLocation(program, "matrix"), lit: gl.getUniformLocation(program, "lit") };

  const upload = (data) => { const b = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, b); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW); return { buffer: b, count: data.length / 9 }; };
  const layers = page.layers.map(layer => {
    const triangles = [], edges = [];
    layer.copies.forEach((copy, index) => {
      const part = surface(copy.cells, tint(copy.ring, index));
      triangles.push(...part.triangles);
      edges.push(...part.edges);
    });
    const all = layer.copies.flatMap(copy => copy.cells.map(place));
    const reach = Math.max(...all.flatMap(p => p.map(Math.abs)));
    return { fill: upload(triangles), lines: upload(edges), radius: reach * 2.6 + 3 };
  });

  // Camera: orbit about the seed's centre, y up. Matrices are column-major.
  const camera = { theta: 0.7, phi: 0.5, radius: layers[0].radius };
  const perspective = (fov, aspect, near, far) => { const f = 1 / Math.tan(fov / 2); return [f / aspect, 0, 0, 0, 0, f, 0, 0, 0, 0, (far + near) / (near - far), -1, 0, 0, 2 * far * near / (near - far), 0]; };
  const lookAt = (eye) => {
    const length = (v) => Math.hypot(...v), norm = (v) => v.map(c => c / length(v));
    const z = norm(eye), x = norm([z[2], 0, -z[0]]), y = [z[1] * x[2] - z[2] * x[1], z[2] * x[0] - z[0] * x[2], z[0] * x[1] - z[1] * x[0]];
    const dot = (a) => -(a[0] * eye[0] + a[1] * eye[1] + a[2] * eye[2]);
    return [x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0, dot(x), dot(y), dot(z), 1];
  };
  const multiply = (a, b) => { const m = new Array(16).fill(0); for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) for (let k = 0; k < 4; k++) m[j * 4 + i] += a[k * 4 + i] * b[j * 4 + k]; return m; };

  let selected = 0;
  const draw = () => {
    const eye = [camera.radius * Math.cos(camera.phi) * Math.sin(camera.theta), camera.radius * Math.sin(camera.phi), camera.radius * Math.cos(camera.phi) * Math.cos(camera.theta)];
    const matrix = multiply(perspective(0.7, canvas.width / canvas.height, 0.1, 1000), lookAt(eye));
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0, 0, 0, 0);
    gl.enable(gl.DEPTH_TEST);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.uniformMatrix4fv(uniforms.matrix, false, new Float32Array(matrix));
    const pass = ({ buffer, count }, mode, lit) => {
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.vertexAttribPointer(attributes.position, 3, gl.FLOAT, false, 36, 0);
      gl.vertexAttribPointer(attributes.normal, 3, gl.FLOAT, false, 36, 12);
      gl.vertexAttribPointer(attributes.color, 3, gl.FLOAT, false, 36, 24);
      gl.uniform1f(uniforms.lit, lit);
      gl.drawArrays(mode, 0, count);
    };
    const layer = layers[selected];
    gl.enable(gl.POLYGON_OFFSET_FILL);
    gl.polygonOffset(1, 1);
    pass(layer.fill, gl.TRIANGLES, 1);
    gl.disable(gl.POLYGON_OFFSET_FILL);
    pass(layer.lines, gl.LINES, 0);
  };

  const show = (index) => { selected = index; camera.radius = layers[index].radius; draw(); };
  document.querySelectorAll('input[name="layer"]').forEach(input =>
    input.addEventListener("change", () => show(Number(input.value))));

  // Drag to orbit, scroll to zoom. Pointer events cover mouse and touch.
  let dragging = null;
  canvas.addEventListener("pointerdown", (e) => { dragging = [e.clientX, e.clientY]; canvas.setPointerCapture(e.pointerId); });
  canvas.addEventListener("pointermove", (e) => {
    if (!dragging) return;
    camera.theta -= (e.clientX - dragging[0]) * 0.01;
    camera.phi = Math.max(-1.5, Math.min(1.5, camera.phi + (e.clientY - dragging[1]) * 0.01));
    dragging = [e.clientX, e.clientY];
    draw();
  });
  canvas.addEventListener("pointerup", () => dragging = null);
  canvas.addEventListener("wheel", (e) => { e.preventDefault(); camera.radius = Math.max(2, Math.min(300, camera.radius * Math.exp(e.deltaY * 0.002))); draw(); }, { passive: false });

  // Height follows width, never read back from the box, so the observer
  // cannot feed itself.
  const resize = () => {
    const width = container.clientWidth, height = Math.round(width * 3 / 4), scale = window.devicePixelRatio;
    canvas.width = Math.round(width * scale);
    canvas.height = Math.round(height * scale);
    draw();
  };
  new ResizeObserver(resize).observe(container);
  resize();
})();
