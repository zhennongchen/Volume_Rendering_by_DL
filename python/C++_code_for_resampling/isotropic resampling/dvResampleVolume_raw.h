#ifndef dv_ResampleVolume_h
#define dv_ResampleVolume_h

// ITK
#include <itkImage.h>
#include <itkIdentityTransform.h>
#include <itkResampleImageFilter.h>
#include <itkImageFileReader.h>
#include <itkImageFileWriter.h>
#include <itkFileTools.h>

#include <itkNearestNeighborInterpolateImageFunction.h>
#include <itkLinearInterpolateImageFunction.h>
#include <itkBSplineInterpolateImageFunction.h>

namespace dv
{

template<unsigned int Dimension, typename TPixel>
void
ResampleVolume(const std::string &IImage,
               const std::string &OImage,
               const double &spacing,
               const unsigned int &interpolator)
{
  using ImageType = itk::Image< TPixel, Dimension >;
  using ReaderType = itk::ImageFileReader< ImageType >;
  using WriterType = itk::ImageFileWriter< ImageType >;
  using TransformType = itk::IdentityTransform< double, Dimension >;
  using ResampleType = itk::ResampleImageFilter< ImageType, ImageType >;

  using NNInterpolateType = itk::NearestNeighborInterpolateImageFunction< ImageType >;
  using LNInterpolateType = itk::LinearInterpolateImageFunction< ImageType >;
  using BSInterpolateType = itk::BSplineInterpolateImageFunction< ImageType >;

  const auto reader = ReaderType::New();
  const auto resample = ResampleType::New();
  const auto writer = WriterType::New();

  reader->SetFileName( IImage );
  reader->Update();

  const auto image = ImageType::New();
  image->Graft( reader->GetOutput() );

  typename ImageType::SpacingType outputSpacing;
  outputSpacing.Fill( spacing );
  auto inputSize = image->GetLargestPossibleRegion().GetSize();
  auto inputSpacing = image->GetSpacing();
  typename ImageType::SizeType outputSize;
  for (unsigned int i = 0; i < Dimension; ++i)
    {
    outputSize[i] = std::floor(double(inputSize[i]) * inputSpacing[i] / outputSpacing[i]);
    }

  resample->SetTransform( TransformType::New() );
  resample->SetOutputStartIndex( image->GetLargestPossibleRegion().GetIndex() );
  resample->SetOutputOrigin( image->GetOrigin() );
  resample->SetOutputDirection( image->GetDirection() );
  resample->SetOutputSpacing( outputSpacing );
  resample->SetSize( outputSize );
  resample->SetInput( image );

  switch ( interpolator )
    {
    case 0:
      {
      const auto interp = NNInterpolateType::New();
      resample->SetInterpolator( interp );
      break;
      }
    case 1:
      {
      const auto interp = LNInterpolateType::New();
      resample->SetInterpolator( interp );
      break;
      }
    default:
      {
      const auto interp = BSInterpolateType::New();
      interp->SetSplineOrder( interpolator );
      resample->SetInterpolator( interp );
      break;
      }
    }

  writer->SetInput( resample->GetOutput() );
  writer->SetFileName( OImage );
  writer->Update();

}

}

#endif
