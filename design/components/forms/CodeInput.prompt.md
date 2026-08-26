Sign-in code entry that reuses \`Tile\` so the first thing a new player touches already looks like the board.

\`\`\`jsx
<CodeInput length={4} value={code} onChange={setCode} />
\`\`\`

Accepts Western or Arabic-Indic digits; a hidden input carries focus and the OS numeric keypad.
