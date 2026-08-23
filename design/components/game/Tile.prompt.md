One board cell — an Arabic letter plus its evaluation state; the atom every كلمات screen is built from.

\`\`\`jsx
<Tile letter="ك" state="correct" animate revealDelay={240} />
\`\`\`

States: \`empty\` (dashed-weight border, no fill), \`filled\` (darker border, letter typed but unsubmitted), \`correct\` (dark brown), \`present\` (light brown), \`absent\` (taupe). Never letter-space the glyph; never use a color outside the brown/taupe ramp for a state.
