import React, { useEffect, useRef, useState } from "react";

export default function Radario({ initialNodes = 6, onSubmit }) {
  const safeOnSubmit = typeof onSubmit === "function" ? onSubmit : () => {};

  // --- State ---
  const [nodes, setNodes] = useState(
    Array.from({ length: initialNodes }, (_, i) => ({
      label: `Node ${i + 1}`,
      value: 0.5,
    }))
  );
  const [focusedIndex, setFocusedIndex] = useState(nodes.length ? 0 : null);
  const [renameIndex, setRenameIndex] = useState(null);
  const [numericMode, setNumericMode] = useState(false);
  const [numericBuffer, setNumericBuffer] = useState("");
  const [snackbar, setSnackbar] = useState(null);
  const [draggingIndex, setDraggingIndex] = useState(null);

  // Refs
  const canvasRef = useRef(null);
  const containerRef = useRef(null);
  const nodePositions = useRef([]);

  // Mock API call for submit
  async function mockApiCall(data) {
    return new Promise((resolve) => setTimeout(() => resolve(true), 1000));
  }

  // --- Keyboard handlers ---
  useEffect(() => {
    const handler = async (e) => {
      // Ctrl+D wipe all nodes
      if (e.ctrlKey && e.key.toLowerCase() === "d") {
        e.preventDefault();
        setNodes([]);
        setFocusedIndex(null);
        setRenameIndex(null);
        setNumericMode(false);
        setNumericBuffer("");
        return;
      }

      // Ctrl+Enter submit
      if (e.ctrlKey && e.key === "Enter") {
        e.preventDefault();
        if (nodes.length === 0) return;
        const dataToSubmit = nodes.map((n, i) => ({
          index: i,
          label: n.label,
          value: n.value,
        }));
        await mockApiCall(dataToSubmit);
        setSnackbar("Polygon Pushed");
        safeOnSubmit(dataToSubmit);
        return;
      }

      // If rename is active, ignore other shortcuts except Escape
      if (renameIndex !== null) {
        if (e.key === "Escape") {
          setRenameIndex(null);
          return;
        }
        return;
      }

      // Enter adds a new node (if not numeric mode)
      if (e.key === "Enter" && !e.shiftKey && !numericMode) {
        e.preventDefault();
        setNodes((prev) => {
          const next = [...prev, { label: `Node ${prev.length + 1}`, value: 0.5 }];
          setFocusedIndex(prev.length);
          return next;
        });
        return;
      }

      // F2 rename focused node
      if (e.key === "F2" && focusedIndex !== null) {
        e.preventDefault();
        setRenameIndex(focusedIndex);
        return;
      }

      // Shift+Enter toggles numeric mode and focuses canvas
      if (e.shiftKey && e.key === "Enter") {
        e.preventDefault();
        if (nodes.length === 0) return;
        if (focusedIndex === null) setFocusedIndex(0);
        setNumericMode(true);
        setNumericBuffer("");
        canvasRef.current?.focus?.();
        return;
      }

      if (!numericMode || focusedIndex === null) return;

      // Numeric input (digits only, max 2 digits)
      if (/^[0-9]$/.test(e.key) && numericBuffer.length < 2) {
        setNumericBuffer((b) => b + e.key);
        return;
      }

      // Commit numeric input with Enter, cycle focus to next node
      if (e.key === "Enter" && numericBuffer.length > 0) {
        e.preventDefault();
        const value = Math.min(99, parseInt(numericBuffer, 10)) / 99;
        setNodes((prev) =>
          prev.map((n, i) => (i === focusedIndex ? { ...n, value } : n))
        );
        const next = (focusedIndex + 1) % nodes.length;
        setFocusedIndex(next);
        setNumericBuffer("");
        setNumericMode(true); // stay numeric
        return;
      }

      // Escape exits numeric mode
      if (e.key === "Escape") {
        setNumericMode(false);
        setNumericBuffer("");
      }
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [focusedIndex, renameIndex, numericMode, numericBuffer, nodes, safeOnSubmit]);

  // --- Snackbar auto-dismiss ---
  useEffect(() => {
    if (!snackbar) return;
    const timer = setTimeout(() => setSnackbar(null), 5000);
    return () => clearTimeout(timer);
  }, [snackbar]);

  // --- Canvas drawing & interaction ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !containerRef.current) return;

    const ctx = canvas.getContext("2d");
    const rect = containerRef.current.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const cx = rect.width / 2;
    const cy = rect.height / 2;
    const radius = Math.min(cx, cy) * 0.38;

    ctx.clearRect(0, 0, rect.width, rect.height);
    if (nodes.length === 0) {
      nodePositions.current = [];
      return;
    }

    const angleStep = (Math.PI * 2) / nodes.length;

    // Draw concentric grids
    ctx.strokeStyle = "rgba(56,189,248,0.2)";
    for (let r = 0.2; r <= 1; r += 0.2) {
      ctx.beginPath();
      nodes.forEach((_, i) => {
        const a = i * angleStep - Math.PI / 2;
        const x = cx + Math.cos(a) * radius * r;
        const y = cy + Math.sin(a) * radius * r;
        i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
      });
      ctx.closePath();
      ctx.stroke();
    }

    // Draw axes and labels
    nodes.forEach((node, i) => {
      const a = i * angleStep - Math.PI / 2;
      const x = cx + Math.cos(a) * radius;
      const y = cy + Math.sin(a) * radius;

      ctx.strokeStyle = "rgba(125,211,252,0.35)";
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(x, y);
      ctx.stroke();

      const lx = cx + Math.cos(a) * (radius + 30);
      const ly = cy + Math.sin(a) * (radius + 30);

      ctx.fillStyle = i === focusedIndex ? "#7dd3fc" : "#bae6fd";
      ctx.font = "14px sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";

      ctx.fillText(
        numericMode && i === focusedIndex
          ? `${node.label} (${numericBuffer.padEnd(2, "_")})`
          : node.label,
        lx,
        ly
      );
    });

    // Draw polygon
    ctx.strokeStyle = "#38bdf8";
    ctx.fillStyle = "rgba(56,189,248,0.28)";
    ctx.beginPath();

    const positions = [];

    nodes.forEach((node, i) => {
      const a = i * angleStep - Math.PI / 2;
      const x = cx + Math.cos(a) * radius * node.value;
      const y = cy + Math.sin(a) * radius * node.value;
      positions.push({ x, y });
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });

    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Draw draggable node circles
    ctx.fillStyle = "#0ea5e9";
    ctx.strokeStyle = "rgba(14,165,233,0.9)";
    positions.forEach(({ x, y }, i) => {
      ctx.beginPath();
      ctx.arc(x, y, 10, 0, 2 * Math.PI);
      ctx.fill();
      ctx.stroke();

      // Draw subtle highlight if dragging
      if (draggingIndex === i) {
        ctx.strokeStyle = "#7dd3fc";
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(x, y, 14, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.lineWidth = 1;
        ctx.strokeStyle = "rgba(14,165,233,0.9)";
      }
    });

    nodePositions.current = positions;
  }, [nodes, focusedIndex, numericMode, numericBuffer, draggingIndex]);

  // --- Drag & Drop support ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();

    function getMousePos(evt) {
      return {
        x: evt.clientX - rect.left,
        y: evt.clientY - rect.top,
      };
    }

    function getTouchPos(touch) {
      return {
        x: touch.clientX - rect.left,
        y: touch.clientY - rect.top,
      };
    }

    function findClosestNode(pos) {
      let closest = -1;
      let closestDist = 20 * 20; // 20px radius squared
      nodePositions.current.forEach(({ x, y }, i) => {
        const dx = pos.x - x;
        const dy = pos.y - y;
        const dist = dx * dx + dy * dy;
        if (dist < closestDist) {
          closest = i;
          closestDist = dist;
        }
      });
      return closest;
    }

    function onPointerDown(evt) {
      const pos =
        evt.touches?.length > 0 ? getTouchPos(evt.touches[0]) : getMousePos(evt);
      const idx = findClosestNode(pos);
      if (idx !== -1) {
        setDraggingIndex(idx);
        evt.preventDefault();
      }
    }

    function onPointerMove(evt) {
      if (draggingIndex === null) return;
      const pos =
        evt.touches?.length > 0 ? getTouchPos(evt.touches[0]) : getMousePos(evt);

      // Calculate angle for node
      const rect = canvas.getBoundingClientRect();
      const cx = rect.width / 2;
      const cy = rect.height / 2;
      const dx = pos.x - cx;
      const dy = pos.y - cy;

      // Get node angle (fixed)
      const angleStep = (Math.PI * 2) / nodes.length;
      const nodeAngle = draggingIndex * angleStep - Math.PI / 2;

      // Project drag position onto axis line of node
      const projLen = dx * Math.cos(nodeAngle) + dy * Math.sin(nodeAngle);

      // Clamp between 0 and max radius
      const maxRadius = Math.min(cx, cy) * 0.38;
      const clamped = Math.min(Math.max(projLen, 0), maxRadius);

      // Convert to value [0..1]
      const newValue = clamped / maxRadius;

      setNodes((prev) =>
        prev.map((n, i) => (i === draggingIndex ? { ...n, value: newValue } : n))
      );
    }

    function onPointerUp() {
      setDraggingIndex(null);
    }

    // Support mouse and touch
    canvas.addEventListener("mousedown", onPointerDown);
    canvas.addEventListener("touchstart", onPointerDown);
    canvas.addEventListener("mousemove", onPointerMove);
    canvas.addEventListener("touchmove", onPointerMove);
    window.addEventListener("mouseup", onPointerUp);
    window.addEventListener("touchend", onPointerUp);

    return () => {
      canvas.removeEventListener("mousedown", onPointerDown);
      canvas.removeEventListener("touchstart", onPointerDown);
      canvas.removeEventListener("mousemove", onPointerMove);
      canvas.removeEventListener("touchmove", onPointerMove);
      window.removeEventListener("mouseup", onPointerUp);
      window.removeEventListener("touchend", onPointerUp);
    };
  }, [draggingIndex, nodes.length]);

  // --- Sidebar UI handlers ---
  function updateNodeLabel(i, val) {
    setNodes((prev) => prev.map((n, j) => (i === j ? { ...n, label: val } : n)));
  }
  function removeNode(i) {
    setNodes((prev) => {
      const next = prev.filter((_, j) => j !== i);
      if (focusedIndex === i) setFocusedIndex(null);
      else if (focusedIndex > i) setFocusedIndex((fi) => fi - 1);
      return next;
    });
  }
  function addNode() {
    setNodes((prev) => {
      const next = [...prev, { label: `Node ${prev.length + 1}`, value: 0.5 }];
      setFocusedIndex(prev.length);
      return next;
    });
  }
  function clearNodes() {
    setNodes([]);
    setFocusedIndex(null);
    setRenameIndex(null);
    setNumericMode(false);
    setNumericBuffer("");
  }

  // Shift+Enter shortcut from sidebar input moves focus to canvas numeric mode
  function handleSidebarKeyDown(e, i) {
    if (e.key === "Enter" && !e.shiftKey && renameIndex === null) {
      e.preventDefault();
      addNode();
    }
    if (e.shiftKey && e.key === "Enter") {
      e.preventDefault();
      if (nodes.length === 0) return;
      setFocusedIndex(i);
      setRenameIndex(null);
      setNumericMode(true);
      setNumericBuffer("");
      canvasRef.current?.focus?.();
    }
    if (e.key === "F2") {
      e.preventDefault();
      setRenameIndex(i);
    }
    if (e.ctrlKey && e.key.toLowerCase() === "d") {
      e.preventDefault();
      clearNodes();
    }
  }

  return (
    <div
      ref={containerRef}
      tabIndex={0}
      style={{
        height: "100vh",
        width: "100vw",
        background: "#020617",
        color: "#e0f2fe",
        outline: "none",
        display: "flex",
        userSelect: "none",
        fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
      }}
    >
      {/* Sidebar */}
      <div
        style={{
          width: 320,
          borderRight: "1px solid #0ea5e9",
          padding: 16,
          boxSizing: "border-box",
          display: "flex",
          flexDirection: "column",
        }}
      >
        <h2 style={{ marginTop: 0, marginBottom: 8, color: "#7dd3fc" }}>Nodes</h2>

        <div
          style={{
            flex: 1,
            overflowY: "auto",
            marginBottom: 12,
          }}
        >
          {nodes.map((node, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                alignItems: "center",
                marginBottom: 8,
              }}
            >
              <input
                type="text"
                value={renameIndex === i ? nodes[i].label : node.label}
                onFocus={() => {
                  setFocusedIndex(i);
                  setRenameIndex(null);
                }}
                onChange={(e) => updateNodeLabel(i, e.target.value)}
                onKeyDown={(e) => handleSidebarKeyDown(e, i)}
                onBlur={() => setRenameIndex(null)}
                style={{
                  flex: 1,
                  padding: "6px 8px",
                  borderRadius: 4,
                  border: "1px solid #0ea5e9",
                  background: "#020617",
                  color: "#e0f2fe",
                  fontSize: 16,
                  outline: renameIndex === i ? "2px solid #7dd3fc" : "none",
                }}
              />
              <button
                onClick={() => removeNode(i)}
                style={{
                  marginLeft: 8,
                  background: "#dc2626",
                  border: "none",
                  borderRadius: 4,
                  color: "white",
                  fontWeight: "bold",
                  cursor: "pointer",
                  padding: "6px 10px",
                  fontSize: 14,
                }}
                aria-label={`Remove node ${node.label}`}
              >
                ×
              </button>
            </div>
          ))}
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          <button
            onClick={addNode}
            style={{
              flex: 1,
              background: "#0ea5e9",
              border: "none",
              borderRadius: 6,
              color: "white",
              fontWeight: "bold",
              padding: "10px 0",
              fontSize: 16,
              cursor: "pointer",
            }}
            aria-label="Add Node"
          >
            Add Node
          </button>
          <button
            onClick={clearNodes}
            style={{
              flex: 1,
              background: "#dc2626",
              border: "none",
              borderRadius: 6,
              color: "white",
              fontWeight: "bold",
              padding: "10px 0",
              fontSize: 16,
              cursor: "pointer",
            }}
            aria-label="Clear All Nodes"
          >
            Clear All
          </button>
        </div>

        <button
          onClick={async () => {
            if (nodes.length === 0) return;
            const dataToSubmit = nodes.map((n, i) => ({
              index: i,
              label: n.label,
              value: n.value,
            }));
            await mockApiCall(dataToSubmit);
            setSnackbar("Polygon Pushed");
            safeOnSubmit(dataToSubmit);
          }}
          style={{
            marginTop: 16,
            width: "100%",
            background: "#0284c7",
            color: "white",
            padding: "12px 0",
            fontWeight: "bold",
            fontSize: 18,
            borderRadius: 8,
            cursor: "pointer",
          }}
          aria-label="Submit / Export Data"
        >
          Submit / Export
        </button>
      </div>

      {/* Canvas */}
      <div
        style={{
          flex: 1,
          position: "relative",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          padding: 20,
          boxSizing: "border-box",
        }}
      >
        <canvas
          ref={canvasRef}
          tabIndex={0}
          style={{
            width: "100%",
            maxWidth: 700,
            maxHeight: 700,
            aspectRatio: "1 / 1",
            border: "2px solid #0ea5e9",
            borderRadius: 12,
            backgroundColor: "#001028",
            touchAction: "none",
            cursor: draggingIndex !== null ? "grabbing" : "grab",
            outline: focusedIndex !== null ? "2px solid #7dd3fc" : "none",
          }}
          aria-label="Radar graph with draggable nodes"
          onFocus={() => {
            if (focusedIndex === null && nodes.length) setFocusedIndex(0);
          }}
        />
        <div
          style={{
            marginTop: 12,
            color: "#7dd3fc",
            fontWeight: "bold",
            fontSize: 14,
            minHeight: 22,
          }}
          aria-live="polite"
          aria-atomic="true"
        >
          {numericMode && focusedIndex !== null
            ? `Editing value for "${nodes[focusedIndex].label}": ${numericBuffer.padEnd(
                2,
                "_"
              )}`
            : ""}
        </div>
      </div>

      {/* Snackbar */}
      {snackbar && (
        <div
          role="alert"
          style={{
            position: "fixed",
            bottom: 24,
            left: "50%",
            transform: "translateX(-50%)",
            backgroundColor: "rgba(14,165,233,0.95)",
            color: "white",
            padding: "12px 24px",
            borderRadius: 8,
            fontWeight: "bold",
            boxShadow: "0 2px 12px rgba(0,0,0,0.3)",
            pointerEvents: "none",
            userSelect: "none",
            zIndex: 9999,
            animation: "fadeinout 5s forwards",
          }}
        >
          {snackbar}
          <style>{`
            @keyframes fadeinout {
              0% {opacity: 0;}
              10% {opacity: 1;}
              90% {opacity: 1;}
              100% {opacity: 0;}
            }
          `}</style>
        </div>
      )}
    </div>
  );
}

