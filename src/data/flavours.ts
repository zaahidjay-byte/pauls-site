export interface Flavour {
  name: string;
  description: string;
}

export interface FlavourCategory {
  name: string;
  flavours: Flavour[];
}

export const flavourCategories: FlavourCategory[] = [
  {
    name: 'Classic',
    flavours: [
      { name: 'Cookies & Cream', description: 'Ultra-creamy vanilla and golden syrup base loaded with oreo crumbs' },
      { name: 'Rocky Road', description: 'Milk chocolate ice cream loaded with gooey homemade marshmallow fluff, chocolate chips' },
      { name: 'Birthday Cake', description: 'Sweet, cakey vanilla ice cream packed with rainbow sprinkles and real funfetti' },
      { name: 'Peppermint Crisp Tart', description: "Scoopable version of South Africa's favourite fridge tart" },
      { name: 'Chocolate Nutella Oreo', description: 'Milk chocolate ice cream swirled with ripples of rich Nutella and crushed oreo' },
      { name: 'Madagascan Vanilla', description: 'Silky-smooth ice cream made with real Madagascan vanilla beans' },
      { name: 'Milk Chocolate', description: 'Smooth, melt-in-your-mouth milk chocolate ice cream made with Belgium Chocolate' },
      { name: 'Vietnamese Coffee Oreo', description: 'Coffee and condensed milk ice cream with chunks of Oreo cookie' },
      { name: 'Salted Caramel Dark Chocolate', description: 'Salted caramel ice cream with flecks of 55% dark chocolate' },
      { name: 'Chocolate Birthday Cake', description: 'Rich chocolate cake ice cream with ribbons of homemade fudge, rainbow sprinkles, and chunks' },
      { name: 'White Chocolate Pretzel', description: 'Creamy white chocolate base with ripples of caramel and studded with salted pretzel brittle' },
      { name: 'Butter Cake', description: 'Cream cheese ice cream folded with chunks of gooey, homemade butter cake' },
      { name: 'Strawberry Cheesecake', description: 'Cream cheese base swirled with sweet strawberry compote' },
    ],
  },
  {
    name: 'Vegan',
    flavours: [
      { name: 'Vegan Dark Chocolate', description: 'Velvety dark chocolate ice cream made with 70% Belgian cocoa and creamy coconut milk' },
      { name: 'Raspberry Sorbet', description: 'Refreshingly smooth, sweet and tart raspberry sorbet made with real fruit' },
      { name: 'Coco Pineapple Sorbet', description: 'Coconut milk sorbet blended with pineapple pulp for a creamy-tropical twist' },
      { name: 'Mango Granadilla Sorbet', description: 'Tropical mango base with tangy granadilla mixed into a bright, juicy sorbet' },
    ],
  },
  {
    name: 'Health',
    flavours: [
      { name: 'Crunchy Peanut Butter', description: 'Creamy peanut butter base with roasted peanut nibs' },
      { name: 'Creamiest Cocoa', description: 'Classic creamy chocolate ice cream made with xylitol' },
      { name: 'Banana Pecan', description: 'Smooth creamy banana ice cream with toasted pecans folded through' },
      { name: 'Toasted Coconut', description: 'Creamy coconut ice cream blended with almonds and toasted coconut' },
    ],
  },
  {
    name: 'Fan Favourites',
    flavours: [
      { name: 'Vegan Peppermint Crisp', description: 'Creamy coconut ice cream infused with vegan caramel, studded with mint chocolate' },
      { name: 'Vegan Latte', description: 'Smooth coconut ice cream base infused with coffee and homemade vegan caramel' },
      { name: 'Red Velvet Brownies', description: 'Creamy red velvet and cream cheese ice cream loaded with red velvet brownie pieces' },
      { name: 'Cookie Dough', description: 'Sweet golden syrup ice cream packed with chewy cookie dough chunks and chocolate nibs' },
      { name: 'Vanilla Honeycomb', description: 'Classic vanilla loaded with crunchy, golden honeycomb chunks' },
      { name: "Mom's Brownie Batter", description: 'Salted caramel ice cream packed with fudgy brownie pieces' },
      { name: 'Malva Pudding', description: 'Creamy dulce and cream cheese ice cream packed with soft, sticky malva cake chunks' },
      { name: 'Rainbow Unicorn', description: 'Soft, cakey vanilla ice cream with a rainbow glow up' },
      { name: 'Dulce de Leche', description: 'Slow-cooked milk caramel churned into a smooth, creamy base' },
    ],
  },
];
