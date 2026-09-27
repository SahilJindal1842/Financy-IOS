"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const accountController_1 = require("../controllers/accountController");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
router.get("/", auth_1.authenticateToken, accountController_1.getAccounts);
router.post("/", auth_1.authenticateToken, accountController_1.createAccount);
exports.default = router;
