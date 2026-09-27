"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resetPassword = exports.forgotPassword = exports.login = exports.verifyOtp = exports.signup = void 0;
const bcrypt_1 = __importDefault(require("bcrypt"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../db/db"));
const EmailService_1 = require("../utils/EmailService");
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();
const signup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, mobile_number, password, name } = req.body;
        if (!email && !mobile_number) {
            return res.status(400).json({ error: "Email or mobile number is required" });
        }
        const query = (0, db_1.default)("users").where(function () {
            if (email)
                this.where({ email });
            if (mobile_number)
                this.orWhere({ mobile_number });
        });
        const existingUser = yield query.first();
        if (existingUser)
            return res.status(400).json({ error: "User already exists" });
        const hashedPassword = yield bcrypt_1.default.hash(password, 10);
        const [user] = yield (0, db_1.default)("users")
            .insert({
            email: email || null,
            mobile_number: mobile_number || null,
            password_hash: hashedPassword,
            name,
            status: "PENDING",
        })
            .returning(["id", "email", "mobile_number", "name"]);
        const otp = generateOTP();
        const otpHash = yield bcrypt_1.default.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 10 * 60000); // 10 mins expiry
        yield (0, db_1.default)("otps").insert({
            user_id: user.id,
            otp_hash: otpHash,
            expires_at: expiresAt,
        });
        yield EmailService_1.EmailService.sendOTP(email || mobile_number, otp);
        res.status(201).json({ message: "User registered successfully. OTP sent for verification." });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.signup = signup;
const verifyOtp = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, mobile_number, otp } = req.body;
        if ((!email && !mobile_number) || !otp) {
            return res.status(400).json({ error: "Email/mobile and OTP are required" });
        }
        const userQuery = (0, db_1.default)("users").where(email ? { email } : { mobile_number });
        const user = yield userQuery.first();
        if (!user)
            return res.status(404).json({ error: "User not found" });
        const otpRecord = yield (0, db_1.default)("otps")
            .where({ user_id: user.id, used: false })
            .andWhere("expires_at", ">", new Date())
            .orderBy("created_at", "desc")
            .first();
        if (!otpRecord)
            return res.status(400).json({ error: "Invalid or expired OTP" });
        const isMatch = yield bcrypt_1.default.compare(otp, otpRecord.otp_hash);
        if (!isMatch)
            return res.status(400).json({ error: "Invalid or expired OTP" });
        yield (0, db_1.default)("otps").where({ id: otpRecord.id }).update({ used: true });
        yield (0, db_1.default)("users")
            .where({ id: user.id })
            .update({
            status: "ACTIVE",
            email_verified: !!email,
            mobile_verified: !!mobile_number,
        });
        res.json({ message: "Verification successful" });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.verifyOtp = verifyOtp;
const login = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, mobile_number, password } = req.body;
        if ((!email && !mobile_number) || !password) {
            return res.status(400).json({ error: "Email/mobile and password are required" });
        }
        const user = yield (0, db_1.default)("users").where(email ? { email } : { mobile_number }).first();
        if (!user)
            return res.status(400).json({ error: "Invalid credentials" });
        if (user.status === "PENDING") {
            return res.status(403).json({ error: "Account pending verification" });
        }
        if (user.status !== "ACTIVE") {
            return res.status(403).json({ error: "Account is not active" });
        }
        const isMatch = yield bcrypt_1.default.compare(password, user.password_hash);
        if (!isMatch)
            return res.status(400).json({ error: "Invalid credentials" });
        yield (0, db_1.default)("users").where({ id: user.id }).update({ last_login_at: new Date() });
        const token = jsonwebtoken_1.default.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET || "supersecretjwt", { expiresIn: "1h" });
        res.json({ token, user: { id: user.id, email: user.email, mobile_number: user.mobile_number, name: user.name, role: user.role } });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.login = login;
const forgotPassword = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, mobile_number } = req.body;
        if (!email && !mobile_number) {
            return res.status(400).json({ error: "Email or mobile number is required" });
        }
        const user = yield (0, db_1.default)("users").where(email ? { email } : { mobile_number }).first();
        if (!user)
            return res.status(404).json({ error: "User not found" });
        const otp = generateOTP();
        const otpHash = yield bcrypt_1.default.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 10 * 60000);
        yield (0, db_1.default)("otps").insert({
            user_id: user.id,
            otp_hash: otpHash,
            expires_at: expiresAt,
        });
        yield EmailService_1.EmailService.sendOTP(email || mobile_number, otp);
        res.json({ message: "Password reset OTP sent" });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.forgotPassword = forgotPassword;
const resetPassword = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { email, mobile_number, otp, new_password } = req.body;
        if ((!email && !mobile_number) || !otp || !new_password) {
            return res.status(400).json({ error: "Missing required fields" });
        }
        const user = yield (0, db_1.default)("users").where(email ? { email } : { mobile_number }).first();
        if (!user)
            return res.status(404).json({ error: "User not found" });
        const otpRecord = yield (0, db_1.default)("otps")
            .where({ user_id: user.id, used: false })
            .andWhere("expires_at", ">", new Date())
            .orderBy("created_at", "desc")
            .first();
        if (!otpRecord)
            return res.status(400).json({ error: "Invalid or expired OTP" });
        const isMatch = yield bcrypt_1.default.compare(otp, otpRecord.otp_hash);
        if (!isMatch)
            return res.status(400).json({ error: "Invalid or expired OTP" });
        const hashedPassword = yield bcrypt_1.default.hash(new_password, 10);
        yield db_1.default.transaction((trx) => __awaiter(void 0, void 0, void 0, function* () {
            yield trx("otps").where({ id: otpRecord.id }).update({ used: true });
            yield trx("users").where({ id: user.id }).update({ password_hash: hashedPassword });
        }));
        res.json({ message: "Password reset successfully" });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.resetPassword = resetPassword;
