// All fixed lists (dropdown choices, wilayas...) live here. Arabic UI.

const String noneLabel = 'لا يوجد';
const String unknownBlood = 'غير معروف';

const Map<int, String> wilayas = {
  1: 'أدرار', 2: 'الشلف', 3: 'الأغواط', 4: 'أم البواقي', 5: 'باتنة',
  6: 'بجاية', 7: 'بسكرة', 8: 'بشار', 9: 'البليدة', 10: 'البويرة',
  11: 'تمنراست', 12: 'تبسة', 13: 'تلمسان', 14: 'تيارت', 15: 'تيزي وزو',
  16: 'الجزائر', 17: 'الجلفة', 18: 'جيجل', 19: 'سطيف', 20: 'سعيدة',
  21: 'سكيكدة', 22: 'سيدي بلعباس', 23: 'عنابة', 24: 'قالمة', 25: 'قسنطينة',
  26: 'المدية', 27: 'مستغانم', 28: 'المسيلة', 29: 'معسكر', 30: 'ورقلة',
  31: 'وهران', 32: 'البيض', 33: 'إليزي', 34: 'برج بوعريريج', 35: 'بومرداس',
  36: 'الطارف', 37: 'تندوف', 38: 'تيسمسيلت', 39: 'الوادي', 40: 'خنشلة',
  41: 'سوق أهراس', 42: 'تيبازة', 43: 'ميلة', 44: 'عين الدفلى', 45: 'النعامة',
  46: 'عين تموشنت', 47: 'غرداية', 48: 'غليزان', 49: 'تيميمون',
  50: 'برج باجي مختار', 51: 'أولاد جلال', 52: 'بني عباس', 53: 'عين صالح',
  54: 'عين قزام', 55: 'تقرت', 56: 'جانت', 57: 'المغير', 58: 'المنيعة',
};

/// "16 - الجزائر" ... used by the wilaya dropdown
final List<String> wilayaOptions = wilayas.entries
    .map((e) => '${e.key.toString().padLeft(2, '0')} - ${e.value}')
    .toList();

const List<String> genders = ['ذكر', 'أنثى'];

const List<String> bloodTypes = [
  unknownBlood, 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

const List<String> vehicleCategories = [
  'سيارة سياحية (VP)',
  'شاحنة خفيفة / سيارة نفعية',
  'شاحنة كبيرة',
  'دراجة نارية',
  'حافلة نقل',
  'دراجة',
];

const List<String> vehicleBrands = [
  'Renault', 'Dacia', 'Peugeot', 'Hyundai', 'Kia', 'Toyota', 'Volkswagen',
  'Seat', 'Skoda', 'Chevrolet', 'Fiat', 'Geely', 'Chery', 'DFSK', 'Suzuki',
  'Nissan', 'علامة أخرى',
];

// The GPL option MUST contain the text 'GPL' (see utils/wilaya.dart isGplFuel).
const List<String> fuelTypes = [
  'بنزين',
  'مازوت',
  'غاز البترول المميع (GPL / سيرغاز)',
  'هجين / كهربائي',
];

const List<String> conditionOptions = [
  'مرض السكري',
  'ضغط الدم',
  'الصرع',
  'الربو / أمراض تنفسية',
  'أمراض القلب',
  'حساسية مفرطة للأدوية',
  'أخرى',
];

const List<String> injuryOptions = [
  'كسور سابقة أو شرائح معدنية',
  'إصابة سابقة في الرقبة أو العمود الفقري',
  'جراحة قلب مفتوح',
  'استئصال الطحال',
  'أخرى',
];
