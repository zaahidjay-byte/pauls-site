export interface Equipment {
  slug: string;
  name: string;
  tagline?: string;
  blurb: string;
  specs: string[];
  ideal?: string;
  /** show the mini-pint units stepper when this setup is selected on /book */
  needsUnits?: boolean;
  /** show the bains stepper when this setup is selected on /book */
  needsBains?: boolean;
  icon: string;
}

export const equipment: Equipment[] = [
  {
    slug: 'phicycle',
    name: 'The Phicycle',
    blurb:
      "No power point? No problem. The Phicycle is our retro ice-cream bicycle, fully self-contained and ready to roll into any space. It serves Paul's mini pints straight from the bike — simple, nostalgic, and zero setup fuss.",
    specs: ['Minimum order: 40 units', 'No electricity required', 'Handles 200+ guests'],
    ideal: "kids' parties, school and sports days, outdoor gatherings, and corporate functions",
    needsUnits: true,
    icon: '🚲',
  },
  {
    slug: 'scooping-freezer',
    name: 'Scooping Freezer',
    tagline: 'Optional gazebo',
    blurb:
      'A freestanding scooping station with a small footprint and big output. Up to 6 bains of your chosen flavours — around 192 scoops — served fresh, with optional toppings. Slots neatly into indoor or outdoor venues, with a gazebo available for open-air events.',
    specs: ['Minimum: 4 bains', '100–250 guests', 'Requires a standard plug point'],
    ideal: 'weddings, corporate events, bar/bat mitzvahs, and large celebrations',
    needsBains: true,
    icon: '🍨',
  },
  {
    slug: 'scooping-cart',
    name: 'Scooping Cart',
    blurb:
      'The classic ice-cream cart, reimagined. Mobile, photogenic, and built for service — up to 6 bains scooped fresh with optional toppings. The centrepiece option for guests who want the full scooping experience.',
    specs: ['Minimum: 4 bains', '100–250 guests', 'Requires a standard plug point'],
    ideal: 'weddings, festivals, brand activations, and celebrations',
    needsBains: true,
    icon: '🛒',
  },
  {
    slug: 'tuk-tuk',
    name: 'The Tuk Tuk',
    tagline: 'Our flagship setup',
    blurb:
      "Our flagship setup. The Paul's Tuk Tuk carries up to 8 bains — around 256 scoops — and can stock mini-pint units alongside, the biggest capacity we offer, with toppings included as an option. It needs room to shine, so it's best suited to outdoor events and large indoor venues.",
    specs: ['Minimum: 4 bains', '200–1,000+ guests', 'Requires a plug point and a generous setup footprint'],
    needsBains: true,
    needsUnits: true,
    icon: '🛺',
  },
  {
    slug: 'countertop-freezer',
    name: 'Countertop Freezer',
    blurb:
      "Our most compact option: a branded countertop freezer serving Paul's mini pints from any table or counter. The lowest-footprint setup for intimate gatherings and indoor venues.",
    specs: ['Minimum order: 60 units', 'Requires a standard plug point'],
    ideal: 'small private events, office functions, and intimate celebrations',
    needsUnits: true,
    icon: '🧊',
  },
];

export const customBrandingCopy =
  "Want it in your colours? We offer custom branding on our equipment — your logo and brand identity on the setup — for clients who want the experience fully theirs. Available at an additional cost; tell us what you have in mind in your quote request.";

export const CONTACT_PHONE_DISPLAY = '061 407 3799';
export const CONTACT_PHONE_TEL = '+27614073799';
export const CONTACT_WHATSAPP = 'https://wa.me/27614073799';
export const INSTAGRAM_HANDLE = '@paulshomemadeevents';
export const INSTAGRAM_URL = 'https://www.instagram.com/paulshomemadeevents';
