const jwt = require('jsonwebtoken');
require('dotenv').config();
const token = jwt.sign({ id: 'f992b135-1406-4fc2-a023-87d650864ed3' }, process.env.JWT_SECRET || 'fallback', { expiresIn: '1h' });
console.log(token);
