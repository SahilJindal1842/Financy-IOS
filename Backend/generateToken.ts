import jwt from 'jsonwebtoken';
const token = jwt.sign({ userId: 'some-uuid' }, process.env.JWT_SECRET || 'fallback_secret', { expiresIn: '1h' });
console.log(token);
