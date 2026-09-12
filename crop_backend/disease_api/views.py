from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .ai_predict import predict_disease
from .models import CropImage
from .serializers import CropImageSerializer


class CropImageUploadView(APIView):

    def post(self, request):

        serializer = CropImageSerializer(data=request.data)

        if serializer.is_valid():

            # Save uploaded image
            crop = serializer.save()

            print("Image Path:", crop.image.path)

            # AI Prediction
            prediction = predict_disease(crop.image.path)

            print("Prediction:", prediction)

            # Save AI prediction into database
            crop.disease_name = prediction["disease"]
            crop.treatment = prediction["treatment"]
            crop.save()

            # Refresh serializer after database update
            serializer = CropImageSerializer(crop)

            return Response(
                {
                    "message": "Prediction Success",
                    "disease": prediction["disease"],
                    "confidence": prediction["confidence"],
                    "treatment": prediction["treatment"],
                    "data": serializer.data,
                },
                status=status.HTTP_201_CREATED,
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST,
        )