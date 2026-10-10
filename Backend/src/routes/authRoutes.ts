import { Router } from "express";
import {
  signup,
  verifyOtp,
  login,
  forgotPassword,
  resetPassword,
  socialLogin,
  firebaseLogin,
  appleAuth,
  googleAuth,
  facebookAuth,
  linkAccount
} from "../controllers/authController";

const router = Router();

router.post("/signup", signup);
router.post("/verify-otp", verifyOtp);
router.post("/login", login);
router.post("/social-login", socialLogin);
router.post("/firebase-login", firebaseLogin);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);

// Dedicated Social Authentication & Account Linking
router.post("/apple", appleAuth);
router.post("/google", googleAuth);
router.post("/facebook", facebookAuth);
router.post("/link-account", linkAccount);

export default router;


