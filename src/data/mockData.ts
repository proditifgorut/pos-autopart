import { faker } from '@faker-js/faker';
import { Product, Customer, Transaction, User } from '../types';

// Mock Products Data
export const generateMockProducts = (count: number = 50): Product[] => {
  const categories = ['Engine', 'Brake', 'Suspension', 'Electrical', 'Body', 'Transmission'];
  const brands = ['Bosch', 'Denso', 'NGK', 'Brembo', 'Monroe', 'KYB', 'Philips', 'Osram'];
  const carModels = ['Toyota Avanza', 'Honda Civic', 'Mitsubishi Xpander', 'Suzuki Ertiga', 'Daihatsu Xenia'];

  return Array.from({ length: count }, () => ({
    id: faker.string.uuid(),
    name: faker.commerce.productName(),
    description: faker.commerce.productDescription(),
    price: parseInt(faker.commerce.price({ min: 50000, max: 5000000 })),
    stock: faker.number.int({ min: 0, max: 100 }),
    category: faker.helpers.arrayElement(categories),
    brand: faker.helpers.arrayElement(brands),
    partNumber: faker.string.alphanumeric({ length: 8 }).toUpperCase(),
    barcode: faker.string.numeric(13),
    image: `https://picsum.photos/400/300?random=${faker.number.int(1000)}`,
    carModel: faker.helpers.arrayElements(carModels, { min: 1, max: 3 }),
    weight: parseFloat(faker.number.float({ min: 0.1, max: 50 }).toFixed(1)),
    dimensions: `${faker.number.int({ min: 10, max: 100 })}x${faker.number.int({ min: 10, max: 100 })}x${faker.number.int({ min: 5, max: 50 })}cm`,
  }));
};

// Mock Customers Data
export const generateMockCustomers = (count: number = 20): Customer[] => {
  return Array.from({ length: count }, () => ({
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    phone: faker.phone.number('08##-####-####'),
    email: faker.internet.email(),
    address: faker.location.streetAddress(),
    type: faker.helpers.arrayElement(['retail', 'wholesale'] as const),
    totalPurchases: parseFloat(faker.number.float({ min: 100000, max: 50000000 }).toFixed(0)),
    lastPurchase: faker.date.recent({ days: 30 }),
  }));
};

// Mock Transactions Data
export const generateMockTransactions = (count: number = 10): Transaction[] => {
  const products = generateMockProducts(10);
  const customers = generateMockCustomers(5);
  
  return Array.from({ length: count }, () => {
    const items = faker.helpers.arrayElements(products, { min: 1, max: 5 }).map(product => ({
      product,
      quantity: faker.number.int({ min: 1, max: 5 }),
      discount: faker.number.float({ min: 0, max: 0.2 }),
    }));

    const subtotal = items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
    const discount = subtotal * 0.05;
    const tax = (subtotal - discount) * 0.11;
    const total = subtotal - discount + tax;

    return {
      id: faker.string.uuid(),
      customerId: faker.helpers.maybe(() => faker.helpers.arrayElement(customers).id),
      customer: faker.helpers.maybe(() => faker.helpers.arrayElement(customers)),
      items,
      subtotal,
      tax,
      discount,
      total,
      paymentMethod: faker.helpers.arrayElement(['cash', 'card', 'transfer', 'qris'] as const),
      paymentAmount: total + faker.number.int({ min: 0, max: 100000 }),
      change: faker.number.int({ min: 0, max: 100000 }),
      date: faker.date.recent({ days: 30 }),
      cashierId: faker.string.uuid(),
      notes: faker.helpers.maybe(() => faker.lorem.sentence()),
    };
  });
};

// Mock User Data
export const mockUser: User = {
  id: '1',
  name: 'Budi Santoso',
  email: 'budi@autoparts.com',
  role: 'cashier',
  avatar: 'https://ui-avatars.com/api/?name=Budi+Santoso&background=0ea5e9&color=fff',
};

export const mockProducts = generateMockProducts();
export const mockCustomers = generateMockCustomers();
export const mockTransactions = generateMockTransactions();
