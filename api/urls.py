from django.urls import path
from .views import ItemList, ItemDetail, LocationList, LocationDetail

urlpatterns = [
    path("items/", ItemList.as_view(), name="item-list"),
    path("items/<int:pk>/", ItemDetail.as_view(), name="item-detail"),
    path("locations/", LocationList.as_view(), name="location-list"),
    path("locations/<int:pk>/", LocationDetail.as_view(), name="location-detail"),
]