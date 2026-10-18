from rest_framework import status
from rest_framework.test import APITestCase

from .models import Item, Location

# If your URLs differ, change these two lines and nothing else.
ITEMS = "/api/v1/items/"
LOCATIONS = "/api/v1/locations/"


def detail(base, pk):
    return f"{base}{pk}/"


def results(response):
    """Works with or without pagination turned on."""
    data = response.data
    return data["results"] if isinstance(data, dict) and "results" in data else data


class LocationTests(APITestCase):
    def setUp(self):
        self.location = Location.objects.create(locationName="Warehouse")

    def test_create_location(self):
        response = self.client.post(LOCATIONS, {"locationName": "Shelf A"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["locationName"], "Shelf A")
        self.assertEqual(Location.objects.count(), 2)

    def test_create_rejects_duplicate_name(self):
        response = self.client.post(LOCATIONS, {"locationName": "Warehouse"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("locationName", response.data)
        self.assertEqual(Location.objects.count(), 1)

    def test_create_rejects_blank_name(self):
        response = self.client.post(LOCATIONS, {"locationName": ""}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_rejects_missing_name(self):
        response = self.client.post(LOCATIONS, {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_rejects_name_over_100_characters(self):
        response = self.client.post(LOCATIONS, {"locationName": "x" * 101}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_locations(self):
        Location.objects.create(locationName="Shelf B")
        response = self.client.get(LOCATIONS)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(results(response)), 2)

    def test_retrieve_location(self):
        response = self.client.get(detail(LOCATIONS, self.location.pk))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["locationName"], "Warehouse")

    def test_retrieve_missing_location_returns_404(self):
        response = self.client.get(detail(LOCATIONS, 9999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_put_replaces_location(self):
        response = self.client.put(
            detail(LOCATIONS, self.location.pk), {"locationName": "Main Store"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.location.refresh_from_db()
        self.assertEqual(self.location.locationName, "Main Store")

    def test_patch_updates_location(self):
        response = self.client.patch(
            detail(LOCATIONS, self.location.pk), {"locationName": "Annex"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.location.refresh_from_db()
        self.assertEqual(self.location.locationName, "Annex")

    def test_delete_location(self):
        response = self.client.delete(detail(LOCATIONS, self.location.pk))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Location.objects.filter(pk=self.location.pk).exists())

    def test_delete_missing_location_returns_404(self):
        response = self.client.delete(detail(LOCATIONS, 9999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_deleting_a_location_also_deletes_its_items(self):
        Item.objects.create(itemName="Laptop", itemLocation=self.location)
        self.client.delete(detail(LOCATIONS, self.location.pk))
        self.assertEqual(Item.objects.count(), 0)


class ItemTests(APITestCase):
    def setUp(self):
        self.warehouse = Location.objects.create(locationName="Warehouse")
        self.office = Location.objects.create(locationName="Office")
        self.item = Item.objects.create(itemName="Laptop", itemLocation=self.warehouse)

    def test_create_item(self):
        payload = {"itemName": "Monitor", "itemLocation": self.office.pk}
        response = self.client.post(ITEMS, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["itemName"], "Monitor")
        self.assertEqual(response.data["itemLocation"], self.office.pk)
        self.assertIn("date_added", response.data)
        self.assertEqual(Item.objects.count(), 2)

    def test_create_ignores_client_supplied_date_added(self):
        payload = {"itemName": "Desk", "itemLocation": self.office.pk, "date_added": "2000-01-01"}
        response = self.client.post(ITEMS, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertNotEqual(response.data["date_added"], "2000-01-01")

    def test_create_rejects_missing_name(self):
        response = self.client.post(ITEMS, {"itemLocation": self.office.pk}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("itemName", response.data)

    def test_create_rejects_missing_location(self):
        response = self.client.post(ITEMS, {"itemName": "Chair"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("itemLocation", response.data)

    def test_create_rejects_unknown_location(self):
        response = self.client.post(ITEMS, {"itemName": "Chair", "itemLocation": 9999}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_rejects_name_over_100_characters(self):
        payload = {"itemName": "x" * 101, "itemLocation": self.office.pk}
        response = self.client.post(ITEMS, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_items(self):
        Item.objects.create(itemName="Printer", itemLocation=self.office)
        response = self.client.get(ITEMS)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(results(response)), 2)

    def test_list_can_be_filtered_by_location(self):
        Item.objects.create(itemName="Printer", itemLocation=self.office)
        response = self.client.get(ITEMS, {"location": self.office.pk})
        names = [row["itemName"] for row in results(response)]
        self.assertEqual(names, ["Printer"])

    def test_filter_with_no_matches_returns_empty_list(self):
        response = self.client.get(ITEMS, {"location": 9999})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(results(response)), 0)

    def test_retrieve_item(self):
        response = self.client.get(detail(ITEMS, self.item.pk))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["itemName"], "Laptop")

    def test_retrieve_missing_item_returns_404(self):
        response = self.client.get(detail(ITEMS, 9999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_put_replaces_item(self):
        payload = {"itemName": "Gaming Laptop", "itemLocation": self.office.pk}
        response = self.client.put(detail(ITEMS, self.item.pk), payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.item.refresh_from_db()
        self.assertEqual(self.item.itemName, "Gaming Laptop")
        self.assertEqual(self.item.itemLocation, self.office)

    def test_put_without_required_field_is_rejected(self):
        response = self.client.put(detail(ITEMS, self.item.pk), {"itemName": "Only name"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_patch_changes_only_the_sent_field(self):
        response = self.client.patch(detail(ITEMS, self.item.pk), {"itemName": "Ultrabook"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.item.refresh_from_db()
        self.assertEqual(self.item.itemName, "Ultrabook")
        self.assertEqual(self.item.itemLocation, self.warehouse)

    def test_delete_item(self):
        response = self.client.delete(detail(ITEMS, self.item.pk))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Item.objects.filter(pk=self.item.pk).exists())

    def test_delete_missing_item_returns_404(self):
        response = self.client.delete(detail(ITEMS, 9999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class ModelTests(APITestCase):
    def test_string_representations(self):
        location = Location.objects.create(locationName="Warehouse")
        item = Item.objects.create(itemName="Laptop", itemLocation=location)
        self.assertEqual(str(location), "Warehouse")
        self.assertEqual(str(item), "Laptop")


class PaginationTests(APITestCase):
    """The project uses PageNumberPagination with PAGE_SIZE = 20."""

    def setUp(self):
        self.location = Location.objects.create(locationName="Warehouse")
        Item.objects.bulk_create(
            [Item(itemName=f"item {i:02d}", itemLocation=self.location) for i in range(25)]
        )

    def test_first_page_has_20_items_and_a_next_link(self):
        response = self.client.get(ITEMS)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 25)
        self.assertEqual(len(response.data["results"]), 20)
        self.assertIsNotNone(response.data["next"])
        self.assertIsNone(response.data["previous"])

    def test_second_page_has_the_remaining_5_items(self):
        response = self.client.get(ITEMS, {"page": 2})
        self.assertEqual(len(response.data["results"]), 5)
        self.assertIsNone(response.data["next"])
        self.assertIsNotNone(response.data["previous"])

    def test_pages_do_not_overlap_or_skip_items(self):
        first = [row["id"] for row in self.client.get(ITEMS).data["results"]]
        second = [row["id"] for row in self.client.get(ITEMS, {"page": 2}).data["results"]]
        self.assertEqual(len(set(first + second)), 25)
        self.assertEqual(first + second, sorted(first + second))

    def test_page_beyond_the_end_returns_404(self):
        response = self.client.get(ITEMS, {"page": 99})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_filter_and_pagination_work_together(self):
        other = Location.objects.create(locationName="Office")
        Item.objects.create(itemName="Printer", itemLocation=other)
        response = self.client.get(ITEMS, {"location": other.pk})
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["itemName"], "Printer")

    def test_locations_are_paginated_too(self):
        for i in range(21):
            Location.objects.create(locationName=f"place {i}")
        response = self.client.get(LOCATIONS)
        self.assertEqual(response.data["count"], 22)
        self.assertEqual(len(response.data["results"]), 20)