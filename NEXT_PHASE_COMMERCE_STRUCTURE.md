# Next Phase Commerce Structure

This is the next app phase after:

- Splash
- Login
- Register

Now the app moves into the full commerce flow.

## Main Screen Flow

```text
Splash
  -> Login / Register
  -> Home
  -> Categories
  -> Product Listing
  -> Product Details
  -> Cart
  -> Checkout
  -> Address
  -> Payment
  -> Order Success
  -> My Orders
  -> Profile
```

## Final Screen List

1. `SplashScreen`
2. `LoginScreen`
3. `SignupScreen`
4. `HomeScreen`
5. `CategoriesScreen`
6. `ProductListingScreen`
7. `ProductDetailsScreen`
8. `CartScreen`
9. `CheckoutScreen`
10. `AddressScreen`
11. `PaymentScreen`
12. `OrderSuccessScreen`
13. `MyOrdersScreen`
14. `ProfileScreen`

## Recommended Navigation Flow

### Auth Flow

```text
Splash -> Login -> Signup -> Home
```

### Shopping Flow

```text
Home -> Categories -> Product Listing -> Product Details -> Cart -> Checkout -> Address -> Payment -> Order Success
```

### Account Flow

```text
Home -> My Orders
Home -> Profile
```

## Responsibilities Of Each Screen

### `SplashScreen`

- Check session/token
- Navigate to auth or app

### `LoginScreen`

- Login form
- Go to register

### `SignupScreen`

- Register form
- Go to login

### `HomeScreen`

- App banner
- Category preview
- Featured products
- Search entry
- Cart shortcut
- Profile shortcut

### `CategoriesScreen`

- Show all categories from API
- Same structure for clothes and grocery
- Only category data changes

### `ProductListingScreen`

- Show products by category
- Grid/list reusable for both app types
- Filter and sort can be added later

### `ProductDetailsScreen`

- Product image
- Name
- Price
- Description
- Quantity selector
- Add to cart

### `CartScreen`

- Cart items
- Quantity update
- Remove item
- Total amount
- Continue to checkout

### `CheckoutScreen`

- Order summary
- Address summary
- Payment summary
- Place order entry

### `AddressScreen`

- Add new address
- Edit address
- Select delivery address

### `PaymentScreen`

- Payment method selection
- COD / online payment options
- Final payment confirmation

### `OrderSuccessScreen`

- Show success message
- Order id
- Continue shopping
- Go to my orders

### `MyOrdersScreen`

- List of placed orders
- Order status
- Order detail entry

### `ProfileScreen`

- User info
- Saved address
- Logout
- Future account settings

## Reusable Structure For Clothes And Grocery

These screens should use the same UI structure:

- `HomeScreen`
- `CategoriesScreen`
- `ProductListingScreen`
- `ProductDetailsScreen`
- `CartScreen`
- `CheckoutScreen`

Only these should change from API data:

- Category title
- Product title
- Product image
- Price
- Description
- Stock
- Variant/unit data

## Suggested Module Structure

```text
lib/
  modules/
    splash/
    auth/
    home/
    categories/
    products/
    cart/
    checkout/
    orders/
    profile/
```

## Suggested File Structure

```text
lib/
  modules/
    splash/
      controllers/
      views/

    auth/
      controllers/
      views/

    home/
      controllers/
      views/

    categories/
      controllers/
      views/

    products/
      controllers/
      views/
        product_listing_screen.dart
        product_details_screen.dart

    cart/
      controllers/
      views/
        cart_screen.dart

    checkout/
      controllers/
      views/
        checkout_screen.dart
        address_screen.dart
        payment_screen.dart
        order_success_screen.dart

    orders/
      controllers/
      views/
        my_orders_screen.dart

    profile/
      controllers/
      views/
        profile_screen.dart
```

## Recommended Build Order

Build in this order:

1. `HomeScreen`
2. `CategoriesScreen`
3. `ProductListingScreen`
4. `ProductDetailsScreen`
5. `CartScreen`
6. `CheckoutScreen`
7. `AddressScreen`
8. `PaymentScreen`
9. `OrderSuccessScreen`
10. `MyOrdersScreen`
11. `ProfileScreen`

## Recommended Data Layer For Next Phase

Create these models next:

- `CategoryModel`
- `ProductModel`
- `CartItemModel`
- `AddressModel`
- `OrderModel`
- `PaymentMethodModel`

Create these repositories/services next:

- `CategoryRepository`
- `ProductRepository`
- `CartRepository`
- `CheckoutRepository`
- `OrderRepository`

## Important Note

Do not build separate UI for clothes and grocery.

Build one reusable commerce UI and map different APIs into the same app models.

That means:

- same screen layout
- same controller logic
- same widget structure
- only API response mapping changes

## Next Practical Step

The next best implementation step is:

1. Replace the temporary `HomeScreen`
2. Add `CategoriesScreen`
3. Add `ProductListingScreen`
4. Add `ProductDetailsScreen`

After that, move into cart and checkout.
