/// All MSA UI copy, verbatim from the design system. Single locale — no
/// i18n framework. Never mix Latin into Arabic sentences; Arabic-Indic
/// digits are applied by callers via toArabicDigits.
library;

abstract final class S {
  // Brand
  static const appTitle = 'كلمات';

  // Header / a11y
  static const help = 'كيف تلعب';
  static const stats = 'الإحصائيات';
  static const settings = 'الإعدادات';
  static const close = 'إغلاق';
  static const emptyTile = 'فارغ';

  // Board area (caller appends the Arabic-Indic puzzle number)
  static const dayBadgePrefix = 'كلمة اليوم ';
  static const answerRevealPrefix = 'الكلمة: ';

  // Toasts
  static const tooShort = 'الكلمة قصيرة';
  static const notInDictionary = 'الكلمة غير موجودة';
  static const win = 'أحسنت!';

  // Keyboard
  static const enterKey = 'إدخال';
  static const deleteKey = 'حذف';

  // Help dialog
  static const helpBody =
      'خمّن كلمة اليوم في ست محاولات. كل محاولة يجب أن تكون كلمة عربية من خمسة حروف.';
  static const helpRuleCorrect = 'الحرف بالبني الغامق في مكانه الصحيح.';
  static const helpRulePresent =
      'الحرف بالبني الفاتح موجود في الكلمة لكن في مكان آخر.';
  static const helpRuleAbsent = 'الحرف الرمادي غير موجود في الكلمة.';
  static const helpStart = 'ابدأ';

  // Stats dialog
  static const statPlayed = 'لُعبت';
  static const statWinRate = 'نسبة الفوز';
  static const statStreak = 'السلسلة';
  static const statBest = 'الأفضل';
  static const distributionTitle = 'توزيع المحاولات';
  static const shareResult = 'مشاركة النتيجة';

  // Settings dialog
  static const settingDark = 'الوضع الليلي';
  static const settingDarkHint = 'خلفية بنية غامقة';
  static const settingHints = 'تلميحات الحروف';
  static const settingHintsHint = 'إظهار الحروف المستبعدة على لوحة المفاتيح';
  static const settingMotion = 'حركة المربعات';

  // Account section (settings)
  static const accountSection = 'حفظ التقدم';
  static const accountHint = 'اربط حسابك ليبقى تقدمك محفوظًا عبر الأجهزة';
  static const continueWithGoogle = 'المتابعة عبر جوجل';
  static const continueWithApple = 'المتابعة عبر آبل';
  static const accountLinked = 'الحساب مرتبط';
  static const displayNameLabel = 'الاسم في المتصدرين';
  static const save = 'حفظ';
  static const switchAccountTitle = 'حساب محفوظ موجود';
  static const switchAccountBody =
      'هذا الحساب مرتبط بتقدم سابق. سيتم التبديل إليه وفقدان تقدم هذا الجهاز.';
  static const switchConfirm = 'التبديل';
  static const cancel = 'إلغاء';
  static const linkFailed = 'تعذّر ربط الحساب';

  // Leaderboard
  static const leaderboard = 'المتصدرون';
  static const leaderboardDaily = 'اليوم';
  static const leaderboardGlobal = 'الإجمالي';
  static const leaderboardEmpty = 'لا نتائج بعد';
  static const leaderboardError = 'تعذّر التحميل';
  static const winsLabel = 'فوز';
}
