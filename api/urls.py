from django.urls import path
from .views import itemList, ItemDetail, LocationList, LocationDetail


urlpatterns = [
    path("item/", itemList.as_view()),
    path("item/<int:pk>/", ItemDetail.as_view()),
    path("Location/", LocationList.as_view()),
    path("Location/<int:pk>/", LocationDetail.as_view()),
]
