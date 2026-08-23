The input surface for every كلمات play screen — alphabetical Arabic rows, RTL, action keys on row three.

\`\`\`jsx
<Keyboard letterStates={{ "ك": "correct", "ت": "absent" }} onKey={type} onEnter={submit} onDelete={back} />
\`\`\`

Never reorder to a QWERTY-mapped Arabic layout; players scan alphabetically. Keys grow to fill width — keep the container at the app max width.
