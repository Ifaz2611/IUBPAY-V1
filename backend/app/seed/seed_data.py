"""Development seed data. Run:  python -m app.seed.seed_data

DEVELOPMENT ONLY. Passwords below are documented test passwords and must
never be used in production."""
from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import SessionLocal, engine
from app.models.menu_item import MenuItem
from app.models.user import User
from app.models.vendor import Vendor
from app.utils.enums import ItemCategory, Role, VendorStatus

# Documented development passwords (prototype only!)
DEV_PASSWORD = "Passw0rd!Dev"

VENDORS = [
    {
        "name": "IUB Main Cafeteria",
        "description": "Main campus cafeteria - rice meals, burgers, snacks",
        "location": "School of Business, Ground Floor",
        "contact_phone": "+8801700000001",
    },
    {
        "name": "IUB Food Court",
        "description": "Food court - sandwiches, tea, coffee and snacks",
        "location": "Permanent Campus, Level 2",
        "contact_phone": "+8801700000002",
    },
]

MENU = {
    "IUB Main Cafeteria": [
        ("Chicken Biryani", "Fragrant basmati biryani with roast chicken", 180, ItemCategory.MEAL),
        ("Beef Burger", "Grilled beef patty with lettuce and sauce", 220, ItemCategory.MEAL),
        ("French Fries", "Crispy golden fries", 120, ItemCategory.SNACK),
        ("Cold Drinks", "Chilled soft drink can", 40, ItemCategory.BEVERAGE),
    ],
    "IUB Food Court": [
        ("Chicken Sandwich", "Toasted chicken sandwich", 150, ItemCategory.MEAL),
        ("Coffee", "Freshly brewed milk coffee", 60, ItemCategory.BEVERAGE),
        ("Tea", "Classic cha with milk", 25, ItemCategory.BEVERAGE),
        ("Singara", "Spicy potato-filled singara", 20, ItemCategory.SNACK),
    ],
}


def run():
    Base_created = None
    from app.db.base import Base
    import app.models  # noqa: F401

    Base.metadata.create_all(engine)

    db = SessionLocal()
    try:
        if db.scalar(select(User).where(User.email == "student@iub.test")):
            print("Seed data already present; skipping.")
            return

        student = User(name="Test Student", email="student@iub.test",
                       password_hash=hash_password(DEV_PASSWORD),
                       student_id="2011234567", phone="+8801800000001",
                       role=Role.STUDENT)
        admin = User(name="Test Admin", email="admin@iub.test",
                     password_hash=hash_password(DEV_PASSWORD), role=Role.ADMIN)
        db.add_all([student, admin])

        vendor_users = {}
        for v in VENDORS:
            vendor = Vendor(**v, status=VendorStatus.APPROVED, settlement_reference=f"SETT-{v['name'][:10].upper().replace(' ', '')}")
            db.add(vendor)
            db.flush()
            staff = User(
                name=f"Staff {v['name']}",
                email=f"vendor{'2' if 'Food Court' in v['name'] else ''}@iub.test",
                password_hash=hash_password(DEV_PASSWORD),
                phone=v["contact_phone"],
                role=Role.VENDOR,
                vendor_id=vendor.id,
            )
            db.add(staff)
            vendor_users[v["name"]] = (vendor, staff)

            for name, desc, price, cat in MENU[v["name"]]:
                db.add(MenuItem(vendor_id=vendor.id, name=name, description=desc,
                                price_taka=price, category=cat, is_available=True))

        db.commit()
        print("Seed complete.")
        print(f"  Student : student@iub.test / {DEV_PASSWORD}")
        print(f"  Vendor  : vendor@iub.test / {DEV_PASSWORD}  (Main Cafeteria)")
        print(f"  Vendor 2: vendor2@iub.test / {DEV_PASSWORD} (Food Court)")
        print(f"  Admin   : admin@iub.test / {DEV_PASSWORD}")
    finally:
        db.close()


if __name__ == "__main__":
    run()
