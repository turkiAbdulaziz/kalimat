/// All MSA UI copy, verbatim from the design system. Single locale — no
/// i18n framework. Never mix Latin into Arabic sentences; Arabic-Indic
/// digits are applied by callers via toArabicDigits.
library;

abstract final class S {
  static const retry = 'حاول مرة أخرى';
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
  static const statsAnswerLabel = 'الكلمة';

  // Toasts
  static const tooShort = 'الكلمة قصيرة';
  static const notInDictionary = 'الكلمة غير موجودة';
  static const win = 'أحسنت!';

  // Keyboard
  static const enterKey = 'إدخال';
  static const deleteKey = 'حذف';

  // Help dialog
  static const helpBody =
      'خمّن كلمة اليوم في ست محاولات. كل محاولة يجب أن تكون كلمة عربية من أربعة حروف.';
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
  static const settingHaptics = 'الاهتزاز';
  static const settingHapticsHint = 'اهتزاز خفيف عند الكتابة والفوز';

  // Account section (settings)
  static const accountSection = 'حفظ التقدم';
  static const accountHint = 'اربط حسابك ليبقى تقدمك محفوظًا عبر الأجهزة';
  static const continueWithGoogle = 'المتابعة عبر جوجل';
  static const continueWithApple = 'المتابعة عبر آبل';
  static const continueWithAppleOfficial = 'Continue with Apple';
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

  // Onboarding: sign-in screen
  static const signInPitch =
      'خمّن كلمة اليوم في ست محاولات. كلمة جديدة كل يوم.';
  static const continueAsGuest = 'المتابعة كزائر';
  static const continueAsGuestEnglish =
      'Continue as guest · No account required';
  static const legalLine = 'بالمتابعة أنت توافق على الشروط وسياسة الخصوصية.';
  static const connectionFailed = 'تعذّر الاتصال';

  // Onboarding: name screen
  static const nameTitle = 'ما اسمك؟';
  static const nameExplainer = 'يظهر هذا الاسم في صفحتك وعند مشاركة نتيجتك.';
  static const nameFieldLabel = 'الاسم الظاهر';
  static const namePlaceholder = 'ليلى';
  static const startPlaying = 'ابدأ اللعب';
  static const skip = 'تخطّي';
  static const guestName = 'زائر';
  static const helloPrefix = 'أهلاً ';

  // Profile screen
  static const profileTitle = 'حسابي';
  static const back = 'رجوع';
  static const viewProfile = 'عرض حسابي';
  static const backToGame = 'العودة إلى اللعبة';
  static const preferences = 'التفضيلات';
  static const signOut = 'تسجيل الخروج';
  static const deleteAccount = 'حذف الحساب';
  static const deleteAccountTitle = 'حذف الحساب نهائيًا';
  static const deleteAccountBody =
      'سيُحذف حسابك ونتائجك وقائمة أصدقائك وتحدّياتك نهائيًا من خوادمنا، '
      'وتُمسح إحصاءاتك من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';
  static const deleteConfirm = 'حذف نهائيًا';
  static const deleteAccountFailed = 'تعذّر حذف الحساب';
  static const editName = 'تعديل الاسم';
  static const shareLastResult = 'مشاركة النتيجة الأخيرة';
  static const streakBadgePrefix = 'سلسلة ';
  static const memberSincePrefix = 'عضو منذ ';
  static const versionPrefix = 'نسخة ';
  static const versionValue = '١٫٠'; // bump alongside pubspec version
  static const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // Duels «التحدّيات»
  static const challenges = 'التحدّيات';
  static const myChallenges =
      'تحدّياتي'; // the tab, so it doesn't echo the title
  static const friends = 'الأصدقاء';
  static const challengeFriend = 'تحدَّ صديقًا';
  static const challengeAction = 'تحدٍّ';
  static const yourTurn = 'دورك';
  static const waitingOpponent = 'بانتظار الخصم';
  static const challengeDone = 'انتهت';
  static const notStarted = 'لم يبدأ';
  static const noChallenges = 'لا تحدّيات بعد';
  static const noChallengesHint = 'تحدَّ صديقًا في كلمة لم يرها أحد منكما.';
  static const noFriends = 'لا أصدقاء بعد';
  static const noRequests = 'لا طلبات';
  static const challengeWon = 'فزت';
  static const challengeLost = 'خسرت';
  static const challengeDraw = 'تعادل';
  static const rematch = 'إعادة التحدي';
  static const vsPrefix = 'تحدٍّ ضد ';
  static const inAttempt = ' في المحاولة ';
  static const challengeExpired = 'انتهت المهلة';
  static const createChallengeFailed = 'تعذّر إنشاء التحدي';
  static const openChallengeFailed = 'تعذّر فتح التحدي';
  static const challengeRecord = 'سجل التحدّيات';
  static const lossesLabel = 'خسارة';

  // Friends
  static const myCode = 'رمزي';
  static const myCodeHint = 'شارك رمزك ليضيفك أصدقاؤك';
  static const copyCode = 'نسخ الرمز';
  static const codeCopied = 'تم نسخ الرمز';
  static const shareMyCode = 'مشاركة رمزي';
  static const shareCodePrefix = 'أضفني في كلمات — رمزي: ';
  static const addFriend = 'إضافة صديق';
  static const friendCodeLabel = 'رمز صديقك';
  static const requests = 'الطلبات';
  static const accept = 'قبول';
  static const decline = 'رفض';
  static const remove = 'إزالة';
  static const removeFriendTitle = 'إزالة صديق';
  static const removeFriendPrefix = 'سيتم إزالة ';
  static const removeFriendSuffix = ' من قائمة أصدقائك.';
  static const requestSent = 'تم إرسال الطلب';
  static const codeNotFound = 'لا يوجد لاعب بهذا الرمز';
  static const alreadyFriends = 'أنتما صديقان بالفعل';
  static const friendActionFailed = 'تعذّر إتمام الطلب';

  // Daily reminder
  static const dailyReminder = 'التنبيه اليومي';
  static const reminderEnable = 'تفعيل';
  static const reminderOff = 'معطّل';
  static const am = 'ص';
  static const pm = 'م';
  static const increase = 'زيادة'; // a11y label on the time steppers
  static const decrease = 'إنقاص';
  static const notificationBody = 'كلمة اليوم بانتظارك.';
}
