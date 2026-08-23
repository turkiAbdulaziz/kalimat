/* @ds-bundle: {"format":4,"namespace":"KalimatDesignSystem_9392cf","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Dialog","sourcePath":"components/core/Dialog.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Switch","sourcePath":"components/core/Switch.jsx"},{"name":"Toast","sourcePath":"components/core/Toast.jsx"},{"name":"DistributionBar","sourcePath":"components/data/DistributionBar.jsx"},{"name":"StatCard","sourcePath":"components/data/StatCard.jsx"},{"name":"GuessGrid","sourcePath":"components/game/GuessGrid.jsx"},{"name":"KeyCap","sourcePath":"components/game/KeyCap.jsx"},{"name":"ARABIC_ROWS","sourcePath":"components/game/Keyboard.jsx"},{"name":"Keyboard","sourcePath":"components/game/Keyboard.jsx"},{"name":"Tile","sourcePath":"components/game/Tile.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"4311e27fb6da","components/core/Button.jsx":"74ea080ccf06","components/core/Dialog.jsx":"37087cf56afd","components/core/IconButton.jsx":"b5aaebc0894e","components/core/Switch.jsx":"305ce4c07290","components/core/Toast.jsx":"faee072468df","components/data/DistributionBar.jsx":"5cb5cbbc9c3f","components/data/StatCard.jsx":"986ab3809ab3","components/game/GuessGrid.jsx":"01f2799ae788","components/game/KeyCap.jsx":"79db2b67b87a","components/game/Keyboard.jsx":"a93a9d75aa59","components/game/Tile.jsx":"9d74d7e6ea15","ui_kits/kalimat_app/App.jsx":"271edef16b18"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.KalimatDesignSystem_9392cf = window.KalimatDesignSystem_9392cf || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
const BADGE_TONES = {
  neutral: {
    background: "var(--surface-sunken)",
    color: "var(--text-muted)"
  },
  accent: {
    background: "var(--accent-soft)",
    color: "var(--brown-800)"
  },
  solid: {
    background: "var(--accent)",
    color: "var(--text-on-accent)"
  }
};
function Badge({
  tone = "neutral",
  children
}) {
  return /*#__PURE__*/React.createElement("span", {
    dir: "rtl",
    style: {
      ...BADGE_TONES[tone],
      display: "inline-block",
      padding: "3px 10px",
      borderRadius: "var(--radius-pill)",
      fontFamily: "var(--font-ui)",
      fontSize: "var(--text-2xs)",
      fontWeight: "var(--weight-semibold)"
    }
  }, children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const BUTTON_VARIANTS = {
  primary: {
    background: "var(--accent)",
    color: "var(--text-on-accent)",
    border: "1px solid var(--accent)"
  },
  secondary: {
    background: "var(--surface-card)",
    color: "var(--text-body)",
    border: "1px solid var(--line)"
  },
  ghost: {
    background: "transparent",
    color: "var(--text-muted)",
    border: "1px solid transparent"
  },
  inverse: {
    background: "var(--brown-100)",
    color: "var(--brown-900)",
    border: "1px solid var(--brown-100)"
  }
};
const BUTTON_SIZES = {
  sm: {
    height: 36,
    padding: "0 14px",
    fontSize: "var(--text-xs)"
  },
  md: {
    height: 44,
    padding: "0 20px",
    fontSize: "var(--text-sm)"
  },
  lg: {
    height: 52,
    padding: "0 28px",
    fontSize: "var(--text-md)"
  }
};
function Button({
  variant = "primary",
  size = "md",
  block = false,
  disabled = false,
  children,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const [press, setPress] = React.useState(false);
  const v = BUTTON_VARIANTS[variant] || BUTTON_VARIANTS.primary;
  const btnStyle = {
    ...v,
    ...BUTTON_SIZES[size],
    width: block ? "100%" : "auto",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    borderRadius: "var(--radius-pill)",
    fontFamily: "var(--font-ui)",
    fontWeight: "var(--weight-semibold)",
    cursor: disabled ? "not-allowed" : "pointer",
    opacity: disabled ? .45 : 1,
    transform: press && !disabled ? "scale(.97)" : "scale(1)",
    filter: hover && !disabled && variant === "primary" ? "brightness(.93)" : "none",
    background: hover && !disabled && (variant === "secondary" || variant === "ghost") ? "var(--surface-sunken)" : v.background,
    transition: "background var(--dur-fast) var(--ease-out), transform var(--dur-instant) var(--ease-out), filter var(--dur-fast) var(--ease-out)",
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    dir: "rtl",
    disabled: disabled,
    style: btnStyle,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPress(false);
    },
    onMouseDown: () => setPress(true),
    onMouseUp: () => setPress(false)
  }, rest), children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function IconButton({
  icon = "settings",
  label,
  size = 40,
  onClick,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (window.lucide) window.lucide.createIcons({
      nameAttr: "data-lucide"
    });
  });
  const iconBtnStyle = {
    width: size,
    height: size,
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    border: "none",
    borderRadius: "var(--radius-pill)",
    background: hover ? "var(--surface-sunken)" : "transparent",
    color: "var(--text-muted)",
    cursor: "pointer",
    transition: "background var(--dur-fast) var(--ease-out)",
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label || icon,
    ref: ref,
    onClick: onClick,
    style: iconBtnStyle,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false)
  }, rest), /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: 20,
      height: 20
    }
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/Dialog.jsx
try { (() => {
function Dialog({
  open = true,
  title,
  onClose,
  footer,
  children,
  width = 380
}) {
  if (!open) return null;
  const overlayStyle = {
    position: "fixed",
    inset: 0,
    background: "var(--surface-overlay)",
    backdropFilter: "blur(2px)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    padding: "var(--space-4)",
    zIndex: 40
  };
  const panelStyle = {
    width: "100%",
    maxWidth: width,
    background: "var(--surface-card)",
    borderRadius: "var(--radius-card)",
    border: "1px solid var(--line-soft)",
    boxShadow: "var(--shadow-lg)",
    padding: "var(--space-6)",
    direction: "rtl",
    fontFamily: "var(--font-ui)",
    color: "var(--text-body)",
    animation: "kalimat-rise var(--dur-base) var(--ease-out)"
  };
  const headStyle = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: "var(--space-4)"
  };
  return /*#__PURE__*/React.createElement("div", {
    style: overlayStyle,
    onClick: onClose
  }, /*#__PURE__*/React.createElement("div", {
    style: panelStyle,
    onClick: e => e.stopPropagation()
  }, /*#__PURE__*/React.createElement("div", {
    style: headStyle
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: 0,
      fontFamily: "var(--font-display)",
      fontSize: "var(--text-lg)",
      fontWeight: "var(--weight-bold)"
    }
  }, title), onClose && /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: "x",
    label: "\u0625\u063A\u0644\u0627\u0642",
    onClick: onClose
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      lineHeight: "var(--leading-body)",
      color: "var(--text-muted)"
    }
  }, children), footer && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: "var(--space-6)"
    }
  }, footer)));
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/core/Switch.jsx
try { (() => {
function Switch({
  checked = false,
  onChange,
  label,
  hint
}) {
  const trackStyle = {
    width: 46,
    height: 28,
    flex: "0 0 auto",
    borderRadius: "var(--radius-pill)",
    background: checked ? "var(--accent)" : "var(--taupe-300)",
    position: "relative",
    cursor: "pointer",
    transition: "background var(--dur-base) var(--ease-out)",
    border: "none"
  };
  const knobStyle = {
    position: "absolute",
    top: 3,
    right: checked ? 21 : 3,
    width: 22,
    height: 22,
    borderRadius: "var(--radius-pill)",
    background: "var(--brown-0)",
    boxShadow: "var(--shadow-sm)",
    transition: "right var(--dur-base) var(--ease-out)"
  };
  return /*#__PURE__*/React.createElement("div", {
    dir: "rtl",
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      gap: "var(--space-4)",
      fontFamily: "var(--font-ui)",
      padding: "var(--space-3) 0",
      borderBottom: "1px solid var(--line-soft)"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      fontWeight: "var(--weight-medium)",
      color: "var(--text-body)"
    }
  }, label), hint && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-2xs)",
      color: "var(--text-subtle)",
      marginTop: 2
    }
  }, hint)), /*#__PURE__*/React.createElement("button", {
    role: "switch",
    "aria-checked": checked,
    "aria-label": label,
    style: trackStyle,
    onClick: () => onChange && onChange(!checked)
  }, /*#__PURE__*/React.createElement("span", {
    style: knobStyle
  })));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Switch.jsx", error: String((e && e.message) || e) }); }

// components/core/Toast.jsx
try { (() => {
function Toast({
  message,
  tone = "neutral",
  visible = true
}) {
  if (!visible) return null;
  const toastStyle = {
    display: "inline-block",
    padding: "10px 18px",
    borderRadius: "var(--radius-pill)",
    background: tone === "success" ? "var(--tile-correct-bg)" : "var(--surface-inverse)",
    color: "var(--text-inverse)",
    fontFamily: "var(--font-ui)",
    fontSize: "var(--text-xs)",
    fontWeight: "var(--weight-semibold)",
    boxShadow: "var(--shadow-md)",
    direction: "rtl",
    animation: "kalimat-rise var(--dur-fast) var(--ease-out)"
  };
  return /*#__PURE__*/React.createElement("div", {
    role: "status",
    style: toastStyle
  }, message);
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Toast.jsx", error: String((e && e.message) || e) }); }

// components/data/DistributionBar.jsx
try { (() => {
const ARABIC_INDIC = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
const toArabicDigits = v => String(v).replace(/[0-9]/g, d => ARABIC_INDIC[Number(d)]);
function DistributionBar({
  guess,
  count = 0,
  max = 1,
  highlight = false
}) {
  const pct = Math.max(6, Math.round(count / (max || 1) * 100));
  return /*#__PURE__*/React.createElement("div", {
    dir: "rtl",
    style: {
      display: "flex",
      alignItems: "center",
      gap: "var(--space-2)",
      fontFamily: "var(--font-ui)",
      fontSize: "var(--text-xs)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 14,
      color: "var(--text-muted)",
      fontWeight: "var(--weight-medium)"
    }
  }, toArabicDigits(guess)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      background: "var(--surface-sunken)",
      borderRadius: "var(--radius-sm)",
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: pct + "%",
      height: "100%",
      background: highlight ? "var(--tile-correct-bg)" : "var(--tile-absent-bg)",
      color: "var(--text-inverse)",
      display: "flex",
      alignItems: "center",
      justifyContent: "flex-start",
      paddingInlineStart: 8,
      boxSizing: "border-box",
      borderRadius: "var(--radius-sm)",
      transition: "width var(--dur-slow) var(--ease-out)",
      fontWeight: "var(--weight-semibold)"
    }
  }, toArabicDigits(count))));
}
Object.assign(__ds_scope, { DistributionBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/DistributionBar.jsx", error: String((e && e.message) || e) }); }

// components/data/StatCard.jsx
try { (() => {
function StatCard({
  value,
  label,
  emphasis = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    dir: "rtl",
    style: {
      textAlign: "center",
      minWidth: 64,
      fontFamily: "var(--font-ui)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: "var(--text-2xl)",
      fontWeight: "var(--weight-bold)",
      color: emphasis ? "var(--accent)" : "var(--text-body)",
      lineHeight: 1
    }
  }, value), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-2xs)",
      color: "var(--text-subtle)",
      marginTop: 6,
      lineHeight: "var(--leading-snug)"
    }
  }, label));
}
Object.assign(__ds_scope, { StatCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/StatCard.jsx", error: String((e && e.message) || e) }); }

// components/game/KeyCap.jsx
try { (() => {
const KEYCAP_STATE_BG = {
  idle: "var(--key-bg)",
  correct: "var(--tile-correct-bg)",
  present: "var(--tile-present-bg)",
  absent: "var(--tile-absent-bg)"
};
function KeyCap({
  label,
  state = "idle",
  wide = false,
  onPress,
  disabled = false,
  children
}) {
  const [held, setHeld] = React.useState(false);
  const isStated = state !== "idle";
  const capStyle = {
    minWidth: wide ? 62 : 30,
    flex: wide ? "0 0 auto" : "1 1 0",
    height: "var(--key-height)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 4,
    padding: wide ? "0 10px" : 0,
    border: "none",
    borderRadius: "var(--radius-key)",
    background: wide && !isStated ? "var(--key-wide-bg)" : KEYCAP_STATE_BG[state],
    color: isStated ? "var(--tile-text-on-state)" : "var(--key-text)",
    fontFamily: "var(--font-ui)",
    fontSize: wide ? "var(--text-xs)" : "var(--text-lg)",
    fontWeight: "var(--weight-semibold)",
    cursor: disabled ? "default" : "pointer",
    opacity: disabled ? .5 : 1,
    transform: held ? "scale(.94)" : "scale(1)",
    transition: "background var(--dur-fast) var(--ease-out), transform var(--dur-instant) var(--ease-out)",
    boxShadow: "var(--shadow-inset)"
  };
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    dir: "rtl",
    disabled: disabled,
    style: capStyle,
    onMouseDown: () => setHeld(true),
    onMouseUp: () => setHeld(false),
    onMouseLeave: () => setHeld(false),
    onClick: () => !disabled && onPress && onPress(label)
  }, children || label);
}
Object.assign(__ds_scope, { KeyCap });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/KeyCap.jsx", error: String((e && e.message) || e) }); }

// components/game/Keyboard.jsx
try { (() => {
const ARABIC_ROWS = [["ا", "ب", "ت", "ث", "ج", "ح", "خ", "د", "ذ", "ر", "ز"], ["س", "ش", "ص", "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ك"], ["ل", "م", "ن", "ه", "و", "ي", "ة", "ى", "ء", "أ", "إ"]];
function Keyboard({
  letterStates = {},
  onKey,
  onEnter,
  onDelete,
  disabled = false
}) {
  const wrapStyle = {
    display: "flex",
    flexDirection: "column",
    gap: "var(--key-gap)",
    width: "100%",
    direction: "rtl"
  };
  const rowStyle = {
    display: "flex",
    gap: "var(--key-gap)"
  };
  return /*#__PURE__*/React.createElement("div", {
    style: wrapStyle
  }, ARABIC_ROWS.map((row, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: rowStyle
  }, i === 2 && /*#__PURE__*/React.createElement(__ds_scope.KeyCap, {
    label: "\u0625\u062F\u062E\u0627\u0644",
    wide: true,
    disabled: disabled,
    onPress: () => onEnter && onEnter()
  }), row.map(l => /*#__PURE__*/React.createElement(__ds_scope.KeyCap, {
    key: l,
    label: l,
    state: letterStates[l] || "idle",
    disabled: disabled,
    onPress: onKey
  })), i === 2 && /*#__PURE__*/React.createElement(__ds_scope.KeyCap, {
    label: "\u062D\u0630\u0641",
    wide: true,
    disabled: disabled,
    onPress: () => onDelete && onDelete()
  }))));
}
Object.assign(__ds_scope, { ARABIC_ROWS, Keyboard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/Keyboard.jsx", error: String((e && e.message) || e) }); }

// components/game/Tile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const TILE_STATE_STYLES = {
  empty: {
    background: "var(--tile-empty-bg)",
    borderColor: "var(--tile-empty-border)",
    color: "var(--text-body)"
  },
  filled: {
    background: "var(--tile-empty-bg)",
    borderColor: "var(--tile-filled-border)",
    color: "var(--text-body)"
  },
  correct: {
    background: "var(--tile-correct-bg)",
    borderColor: "var(--tile-correct-border)",
    color: "var(--tile-text-on-state)"
  },
  present: {
    background: "var(--tile-present-bg)",
    borderColor: "var(--tile-present-border)",
    color: "var(--tile-text-on-state)"
  },
  absent: {
    background: "var(--tile-absent-bg)",
    borderColor: "var(--tile-absent-border)",
    color: "var(--tile-text-on-state)"
  }
};
function Tile({
  letter = "",
  state = "empty",
  size,
  animate = false,
  revealDelay = 0,
  style,
  ...rest
}) {
  const dim = size || "var(--tile-size)";
  const tileStyle = {
    width: dim,
    height: dim,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    boxSizing: "border-box",
    border: "2px solid",
    borderRadius: "var(--radius-tile)",
    fontFamily: "var(--font-display)",
    fontSize: "var(--text-tile)",
    fontWeight: "var(--weight-bold)",
    lineHeight: 1,
    userSelect: "none",
    transition: "background var(--dur-fast) var(--ease-out), border-color var(--dur-fast) var(--ease-out)",
    animation: animate ? state === "empty" || state === "filled" ? "kalimat-pop var(--dur-base) var(--ease-pop) " + revealDelay + "ms both" : "kalimat-flip var(--dur-slow) var(--ease-in-out) " + revealDelay + "ms both" : "none",
    ...TILE_STATE_STYLES[state],
    ...style
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    dir: "rtl",
    "aria-label": letter || "فارغ",
    style: tileStyle
  }, rest), letter);
}
Object.assign(__ds_scope, { Tile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/Tile.jsx", error: String((e && e.message) || e) }); }

// components/game/GuessGrid.jsx
try { (() => {
function GuessGrid({
  rows = [],
  wordLength = 5,
  maxGuesses = 6,
  shakeRow = -1,
  revealRow = -1,
  tileSize
}) {
  const gridStyle = {
    display: "grid",
    gap: "var(--grid-gap)",
    justifyContent: "center",
    direction: "rtl"
  };
  const rowStyle = {
    display: "grid",
    gridTemplateColumns: "repeat(" + wordLength + ", auto)",
    gap: "var(--tile-gap)"
  };
  const all = [];
  for (let r = 0; r < maxGuesses; r++) {
    const row = rows[r] || [];
    const cells = [];
    for (let c = 0; c < wordLength; c++) {
      const cell = row[c] || {};
      cells.push(/*#__PURE__*/React.createElement(__ds_scope.Tile, {
        key: c,
        letter: cell.letter || "",
        state: cell.state || (cell.letter ? "filled" : "empty"),
        size: tileSize,
        animate: r === revealRow,
        revealDelay: r === revealRow ? c * 120 : 0
      }));
    }
    all.push(/*#__PURE__*/React.createElement("div", {
      key: r,
      style: {
        ...rowStyle,
        animation: r === shakeRow ? "kalimat-shake var(--dur-slow) var(--ease-in-out)" : "none"
      }
    }, cells));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: gridStyle
  }, all);
}
Object.assign(__ds_scope, { GuessGrid });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/GuessGrid.jsx", error: String((e && e.message) || e) }); }

// ui_kits/kalimat_app/App.jsx
try { (() => {
const {
  Button,
  IconButton,
  Badge,
  Toast,
  Switch,
  Tile,
  GuessGrid,
  Keyboard,
  StatCard,
  DistributionBar,
  Dialog
} = window.KalimatDesignSystem_9392cf;
const TARGET = ["م", "د", "ر", "س", "ة"];
const WORD_LENGTH = 5,
  MAX_GUESSES = 6;
function evaluateGuess(guess) {
  const res = guess.map(() => "absent");
  const pool = {};
  TARGET.forEach((l, i) => {
    if (guess[i] === l) res[i] = "correct";else pool[l] = (pool[l] || 0) + 1;
  });
  guess.forEach((l, i) => {
    if (res[i] !== "correct" && pool[l]) {
      res[i] = "present";
      pool[l]--;
    }
  });
  return res;
}
function Header({
  onHelp,
  onStats,
  onSettings
}) {
  const headerStyle = {
    height: "var(--header-height)",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "0 var(--space-3)",
    borderBottom: "1px solid var(--line-soft)",
    background: "var(--surface-card)"
  };
  return /*#__PURE__*/React.createElement("header", {
    dir: "rtl",
    style: headerStyle
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: "var(--space-2)"
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "circle-help",
    label: "\u0643\u064A\u0641 \u062A\u0644\u0639\u0628",
    onClick: onHelp
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: "var(--text-xl)",
      fontWeight: "var(--weight-black)",
      color: "var(--brown-800)"
    }
  }, "\u0643\u0644\u0645\u0627\u062A"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 2
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "bar-chart-3",
    label: "\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A",
    onClick: onStats
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "settings",
    label: "\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A",
    onClick: onSettings
  })));
}
function HelpDialog({
  open,
  onClose
}) {
  const example = [{
    letter: "م",
    state: "correct"
  }, {
    letter: "ك",
    state: "absent"
  }, {
    letter: "ت",
    state: "present"
  }, {
    letter: "ب",
    state: "absent"
  }, {
    letter: "ة",
    state: "absent"
  }];
  return /*#__PURE__*/React.createElement(Dialog, {
    open: open,
    title: "\u0643\u064A\u0641 \u062A\u0644\u0639\u0628",
    onClose: onClose,
    footer: /*#__PURE__*/React.createElement(Button, {
      block: true,
      onClick: onClose
    }, "\u0627\u0628\u062F\u0623")
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      marginTop: 0
    }
  }, "\u062E\u0645\u0651\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u064A\u0648\u0645 \u0641\u064A \u0633\u062A \u0645\u062D\u0627\u0648\u0644\u0627\u062A. \u0643\u0644 \u0645\u062D\u0627\u0648\u0644\u0629 \u064A\u062C\u0628 \u0623\u0646 \u062A\u0643\u0648\u0646 \u0643\u0644\u0645\u0629 \u0639\u0631\u0628\u064A\u0629 \u0645\u0646 \u062E\u0645\u0633\u0629 \u062D\u0631\u0648\u0641."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--tile-gap)",
      justifyContent: "center",
      margin: "var(--space-4) 0"
    }
  }, example.map((c, i) => /*#__PURE__*/React.createElement(Tile, {
    key: i,
    letter: c.letter,
    state: c.state,
    size: 44
  }))), /*#__PURE__*/React.createElement("ul", {
    style: {
      paddingInlineStart: 18,
      margin: 0,
      display: "grid",
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("li", null, "\u0627\u0644\u062D\u0631\u0641 \u0628\u0627\u0644\u0628\u0646\u064A \u0627\u0644\u063A\u0627\u0645\u0642 \u0641\u064A \u0645\u0643\u0627\u0646\u0647 \u0627\u0644\u0635\u062D\u064A\u062D."), /*#__PURE__*/React.createElement("li", null, "\u0627\u0644\u062D\u0631\u0641 \u0628\u0627\u0644\u0628\u0646\u064A \u0627\u0644\u0641\u0627\u062A\u062D \u0645\u0648\u062C\u0648\u062F \u0641\u064A \u0627\u0644\u0643\u0644\u0645\u0629 \u0644\u0643\u0646 \u0641\u064A \u0645\u0643\u0627\u0646 \u0622\u062E\u0631."), /*#__PURE__*/React.createElement("li", null, "\u0627\u0644\u062D\u0631\u0641 \u0627\u0644\u0631\u0645\u0627\u062F\u064A \u063A\u064A\u0631 \u0645\u0648\u062C\u0648\u062F \u0641\u064A \u0627\u0644\u0643\u0644\u0645\u0629.")));
}
function StatsDialog({
  open,
  onClose,
  won,
  guessCount
}) {
  const dist = [["١", 1], ["٢", 4], ["٣", 9], ["٤", 14], ["٥", 6], ["٦", 2]];
  const arabicNum = ["", "١", "٢", "٣", "٤", "٥", "٦"];
  return /*#__PURE__*/React.createElement(Dialog, {
    open: open,
    title: won ? "أحسنت!" : "الإحصائيات",
    onClose: onClose,
    footer: /*#__PURE__*/React.createElement(Button, {
      block: true,
      variant: "secondary",
      onClick: onClose
    }, "\u0645\u0634\u0627\u0631\u0643\u0629 \u0627\u0644\u0646\u062A\u064A\u062C\u0629")
  }, won && /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: "center",
      marginBottom: "var(--space-4)"
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "accent"
  }, "كلمات ٢٤٧ — " + arabicNum[guessCount] + "/٦")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      marginBottom: "var(--space-6)"
    }
  }, /*#__PURE__*/React.createElement(StatCard, {
    value: "\u0668\u0666",
    label: "\u0644\u064F\u0639\u0628\u062A"
  }), /*#__PURE__*/React.createElement(StatCard, {
    value: "\u0666\u0664\u066A",
    label: "\u0646\u0633\u0628\u0629 \u0627\u0644\u0641\u0648\u0632",
    emphasis: true
  }), /*#__PURE__*/React.createElement(StatCard, {
    value: "\u0661\u0662",
    label: "\u0627\u0644\u0633\u0644\u0633\u0644\u0629"
  }), /*#__PURE__*/React.createElement(StatCard, {
    value: "\u0662\u0661",
    label: "\u0627\u0644\u0623\u0641\u0636\u0644"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-2xs)",
      color: "var(--text-subtle)",
      marginBottom: "var(--space-2)"
    }
  }, "\u062A\u0648\u0632\u064A\u0639 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0627\u062A"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: 6
    }
  }, dist.map(([g, c]) => /*#__PURE__*/React.createElement(DistributionBar, {
    key: g,
    guess: g,
    count: c,
    max: 14,
    highlight: won && g === arabicNum[guessCount]
  }))));
}
function SettingsDialog({
  open,
  onClose,
  settings,
  setSettings
}) {
  const set = k => v => setSettings(s => ({
    ...s,
    [k]: v
  }));
  return /*#__PURE__*/React.createElement(Dialog, {
    open: open,
    title: "\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A",
    onClose: onClose
  }, /*#__PURE__*/React.createElement(Switch, {
    label: "\u0627\u0644\u0648\u0636\u0639 \u0627\u0644\u0644\u064A\u0644\u064A",
    hint: "\u062E\u0644\u0641\u064A\u0629 \u0628\u0646\u064A\u0629 \u063A\u0627\u0645\u0642\u0629",
    checked: settings.dark,
    onChange: set("dark")
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "\u062A\u0644\u0645\u064A\u062D\u0627\u062A \u0627\u0644\u062D\u0631\u0648\u0641",
    hint: "\u0625\u0638\u0647\u0627\u0631 \u0627\u0644\u062D\u0631\u0648\u0641 \u0627\u0644\u0645\u0633\u062A\u0628\u0639\u062F\u0629 \u0639\u0644\u0649 \u0644\u0648\u062D\u0629 \u0627\u0644\u0645\u0641\u0627\u062A\u064A\u062D",
    checked: settings.hints,
    onChange: set("hints")
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "\u062D\u0631\u0643\u0629 \u0627\u0644\u0645\u0631\u0628\u0639\u0627\u062A",
    checked: settings.motion,
    onChange: set("motion")
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: "var(--space-4)",
      fontSize: "var(--text-2xs)",
      color: "var(--text-subtle)"
    }
  }, "\u0643\u0644\u0645\u0627\u062A \u0662\u0664\u0667 \xB7 \u0646\u0633\u062E\u0629 \u0661\u066B\u0664"));
}
function App() {
  const [rows, setRows] = React.useState([]);
  const [current, setCurrent] = React.useState([]);
  const [letterStates, setLetterStates] = React.useState({});
  const [toast, setToast] = React.useState(null);
  const [shakeRow, setShakeRow] = React.useState(-1);
  const [revealRow, setRevealRow] = React.useState(-1);
  const [dialog, setDialog] = React.useState("help");
  const [won, setWon] = React.useState(false);
  const [settings, setSettings] = React.useState({
    dark: false,
    hints: true,
    motion: true
  });
  React.useEffect(() => {
    if (window.lucide) window.lucide.createIcons({
      nameAttr: "data-lucide"
    });
  });
  const flash = m => {
    setToast(m);
    setTimeout(() => setToast(null), 1300);
  };
  const onKey = l => {
    if (!won && current.length < WORD_LENGTH) setCurrent(c => [...c, l]);
  };
  const onDelete = () => setCurrent(c => c.slice(0, -1));
  const onEnter = () => {
    if (won) return;
    if (current.length < WORD_LENGTH) {
      setShakeRow(rows.length);
      flash("الكلمة قصيرة");
      setTimeout(() => setShakeRow(-1), 450);
      return;
    }
    const states = evaluateGuess(current);
    const row = current.map((letter, i) => ({
      letter,
      state: states[i]
    }));
    const idx = rows.length;
    setRows(r => [...r, row]);
    setRevealRow(idx);
    setLetterStates(ls => {
      const next = {
        ...ls
      };
      const rank = {
        absent: 0,
        present: 1,
        correct: 2
      };
      row.forEach(c => {
        if (!next[c.letter] || rank[c.state] > rank[next[c.letter]]) next[c.letter] = c.state;
      });
      return next;
    });
    setCurrent([]);
    const solved = states.every(s => s === "correct");
    setTimeout(() => setRevealRow(-1), 900);
    if (solved) {
      setWon(true);
      flash("أحسنت!");
      setTimeout(() => setDialog("stats"), 1400);
    } else if (idx + 1 >= MAX_GUESSES) {
      setTimeout(() => setDialog("stats"), 1000);
    }
  };
  const displayRows = [...rows];
  if (current.length && rows.length < MAX_GUESSES) displayRows[rows.length] = current.map(l => ({
    letter: l,
    state: "filled"
  }));
  const appStyle = {
    minHeight: "100vh",
    background: settings.dark ? "var(--brown-900)" : "var(--surface-page)",
    display: "flex",
    justifyContent: "center",
    colorScheme: settings.dark ? "dark" : "light"
  };
  const columnStyle = {
    width: "var(--app-max-width)",
    display: "flex",
    flexDirection: "column",
    minHeight: "100vh",
    background: settings.dark ? "var(--brown-900)" : "var(--surface-page)"
  };
  return /*#__PURE__*/React.createElement("div", {
    style: appStyle
  }, /*#__PURE__*/React.createElement("div", {
    style: columnStyle
  }, /*#__PURE__*/React.createElement(Header, {
    onHelp: () => setDialog("help"),
    onStats: () => setDialog("stats"),
    onSettings: () => setDialog("settings")
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      padding: "var(--space-4) var(--gutter)",
      gap: "var(--space-4)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 34,
      display: "flex",
      alignItems: "center"
    }
  }, toast ? /*#__PURE__*/React.createElement(Toast, {
    message: toast,
    tone: won ? "success" : "neutral"
  }) : /*#__PURE__*/React.createElement(Badge, null, "\u0643\u0644\u0645\u0629 \u0627\u0644\u064A\u0648\u0645 \u0662\u0664\u0667")), /*#__PURE__*/React.createElement(GuessGrid, {
    rows: displayRows,
    wordLength: WORD_LENGTH,
    maxGuesses: MAX_GUESSES,
    shakeRow: shakeRow,
    revealRow: settings.motion ? revealRow : -1
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--space-2) var(--space-2) var(--space-4)"
    }
  }, /*#__PURE__*/React.createElement(Keyboard, {
    letterStates: settings.hints ? letterStates : {},
    onKey: onKey,
    onEnter: onEnter,
    onDelete: onDelete,
    disabled: won
  }))), /*#__PURE__*/React.createElement(HelpDialog, {
    open: dialog === "help",
    onClose: () => setDialog(null)
  }), /*#__PURE__*/React.createElement(StatsDialog, {
    open: dialog === "stats",
    onClose: () => setDialog(null),
    won: won,
    guessCount: rows.length
  }), /*#__PURE__*/React.createElement(SettingsDialog, {
    open: dialog === "settings",
    onClose: () => setDialog(null),
    settings: settings,
    setSettings: setSettings
  }));
}
Object.assign(window, {
  App,
  Header,
  HelpDialog,
  StatsDialog,
  SettingsDialog
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/kalimat_app/App.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.DistributionBar = __ds_scope.DistributionBar;

__ds_ns.StatCard = __ds_scope.StatCard;

__ds_ns.GuessGrid = __ds_scope.GuessGrid;

__ds_ns.KeyCap = __ds_scope.KeyCap;

__ds_ns.ARABIC_ROWS = __ds_scope.ARABIC_ROWS;

__ds_ns.Keyboard = __ds_scope.Keyboard;

__ds_ns.Tile = __ds_scope.Tile;

})();
