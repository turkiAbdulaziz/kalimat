The كلمات board — use it for any playing surface; it owns RTL order and row spacing so callers never do grid math.

\`\`\`jsx
<GuessGrid rows={[[{letter:"ك",state:"correct"},{letter:"ت",state:"absent"}]]} wordLength={5} maxGuesses={6} revealRow={0} />
\`\`\`

Rows fill from index 0 downward. \`shakeRow\` for a rejected word, \`revealRow\` to cascade the flip.
