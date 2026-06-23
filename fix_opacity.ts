import * as fs from 'fs';
import * as path from 'path';

function walk(dir: string) {
  let results: string[] = [];
  const list = fs.readdirSync(dir);
  list.forEach(function(file) {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) { 
      results = results.concat(walk(file));
    } else { 
      if (file.endsWith('.dart')) results.push(file);
    }
  });
  return results;
}

const files = walk('./lib');
let fixedFiles = 0;

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  let newContent = content.replace(/\.withOpacity\(([^)]+)\)/g, '.withValues(alpha: $1)');
  if (content !== newContent) {
    fs.writeFileSync(file, newContent, 'utf8');
    fixedFiles++;
  }
}

console.log(`Fixed .withOpacity in ${fixedFiles} files.`);
