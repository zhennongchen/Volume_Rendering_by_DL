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

#include <itkChangeLabelsImageFilter.h>
#include <itkBinaryThresholdImageFilter.h>
#include <itkImageFileWriter.h>
#include <itkComposeImageFilter.h>

#include <itkVectorImage.h>
#include <itkIndexOfMaxImageFilter.h>

#include <dvImageToSet.h>

namespace dv
{

template <unsigned int Dimension, typename TPixel>
void ResampleVolume(const std::string &IImage,
                    const std::string &OImage,
                    const double &spacing,
                    const double &spacingx,
                    const double &spacingy,
                    const double &spacingz,
                    const int &outx,
                    const int &outy,
                    const int &outz,
                    const std::string &OImage_target,
                    const unsigned int &interpolator)
{
  using ImageType = itk::Image<TPixel, Dimension>;
  using ReaderType = itk::ImageFileReader<ImageType>;
  using WriterType = itk::ImageFileWriter<ImageType>;
  using TransformType = itk::IdentityTransform<float, Dimension>;
  using ResampleType = itk::ResampleImageFilter<ImageType, ImageType, float, float>;

  // Image and filter types for linear resampling segmentation by label
  using ImageTypeML = itk::Image<float, Dimension>;
  using ResampleTypeML = itk::ResampleImageFilter<ImageType, ImageTypeML, float, float>;
 
  using VectorImageType = itk::VectorImage<float, Dimension>;
  using ChangeLabelsFilterType = itk::ChangeLabelsImageFilter<ImageType>;
  using ImageToVectorImageFilterType = itk::ComposeImageFilter<ImageTypeML>;
  using MaxFilterType = itk::IndexOfMaxImageFilter<VectorImageType, ImageType>;

  // Interpolator types
  using NNInterpolateType = itk::NearestNeighborInterpolateImageFunction<ImageType, float>;
  using LNInterpolateType = itk::LinearInterpolateImageFunction<ImageType, float>;
  using BSInterpolateType = itk::BSplineInterpolateImageFunction<ImageType, float>;

  const auto reader = ReaderType::New();
  const auto reader_target = ReaderType::New();
  const auto writer = WriterType::New();

  // Read input image file
  reader->SetFileName(IImage);
  reader->Update();

  // Graft onto an ImageType
  const auto image = ImageType::New();
  image->Graft(reader->GetOutput());

  

  // Create ImageType for resampled output
  auto inputSize = image->GetLargestPossibleRegion().GetSize();
  auto inputSpacing = image->GetSpacing();
  typename ImageType::SpacingType outputSpacing;
  typename ImageType::SizeType outputSize;
  if (OImage_target != "") {
    // Read target size image file
    reader_target->SetFileName(OImage_target);
    reader_target->Update();
    // Graft onto an ImageType
    const auto target_size_image = ImageType::New();
    target_size_image->Graft(reader_target->GetOutput());
    outputSpacing = target_size_image->GetSpacing();
    outputSize = target_size_image->GetLargestPossibleRegion().GetSize();
  } else {
    if (spacing != 0) {
      outputSpacing.Fill(spacing);
      for (unsigned int i = 0; i < Dimension; ++i)
      {
        outputSize[i] = std::floor(double(inputSize[i]) * inputSpacing[i] / outputSpacing[i]);
      }
    } else {
      for (unsigned int i = 0; i < Dimension; ++i) {
        if (i == 0) outputSize[i] = outx;
        else if (i == 1) outputSize[i] = outy;
        else outputSize[i] = outz;
      }
      for (unsigned int i = 0; i < Dimension; ++i)
      {
        if (i == 0) outputSpacing[i] = spacingx;
        else if (i == 1) outputSpacing[i] = spacingy;
        else outputSpacing[i] = spacingz;
      }
    }
    
  }
  
  

  // create resample filter
  auto resample = ResampleType::New();
  if (interpolator != 2) {
    resample->SetTransform(TransformType::New());
    resample->SetOutputStartIndex(image->GetLargestPossibleRegion().GetIndex());
    resample->SetOutputOrigin(image->GetOrigin());
    resample->SetOutputDirection(image->GetDirection());
    resample->SetOutputSpacing(outputSpacing);
    resample->SetSize(outputSize);
    resample->SetInput(image);
  }
  

  switch (interpolator)
  {
  case 0: // Nearest Neighbor
  {
    const auto interp = NNInterpolateType::New();
    resample->SetInterpolator(interp);
    writer->SetInput(resample->GetOutput());

    break;
  }
  case 1: // Linear
  {
    const auto interp = LNInterpolateType::New();
    resample->SetInterpolator(interp);
    writer->SetInput(resample->GetOutput());

    break;
  }
  case 2: // Linear by segmentation label
  {

    // linearly interpolate labels separately
    const auto interp = LNInterpolateType::New();
    const auto imageToVectorImageFilter = ImageToVectorImageFilterType::New();

    // create label maps (all initially map to 0)
    const auto labels_set = dv::ImageToSet<Dimension, TPixel>(image);
    std::map<TPixel, TPixel> label_map;
    std::map<TPixel, TPixel> layer_map;
    std::map<TPixel, TPixel> rev_label_map;
    int label = 0;
    for (const auto &x : labels_set)
    {
      int s = (int)x;
      label_map[s] = 0;
      layer_map[s] = label;
      rev_label_map[label] = s;
      label++;
    }

    for (const auto &x : labels_set)
    {
      int s = (int)x;

      // binarize image
      label_map[s] = 1;
      const auto filter = ChangeLabelsFilterType::New();
      filter->SetLabelMap(label_map);
      filter->SetInput(reader->GetOutput());

      // create resample filter for current label
      auto resample = ResampleTypeML::New();
      resample->SetTransform(TransformType::New());
      resample->SetOutputStartIndex(image->GetLargestPossibleRegion().GetIndex());
      resample->SetOutputOrigin(image->GetOrigin());
      resample->SetOutputDirection(image->GetDirection());
      resample->SetOutputSpacing(outputSpacing);
      resample->SetSize(outputSize);
      resample->SetInput(filter->GetOutput());
      resample->SetInterpolator(interp);
      resample->Update();

      // add output of resample to composite filter
      imageToVectorImageFilter->SetInput(layer_map[s], resample->GetOutput());
      imageToVectorImageFilter->Update();

      // reset label_map
      label_map[s] = 0;
    }

    // get the max of each vector in VectorImage output from imageToVectorImageFilter
    const auto maxFilter = MaxFilterType::New();
    maxFilter->SetInput(imageToVectorImageFilter->GetOutput());
    maxFilter->Update();

    const auto revert_labels_filter = ChangeLabelsFilterType::New();
    revert_labels_filter->SetLabelMap(rev_label_map);
    revert_labels_filter->SetInput(maxFilter->GetOutput());
    revert_labels_filter->Update();

    writer->SetInput(revert_labels_filter->GetOutput());

    break;
  }
  default: // BSpline
  {
    const auto interp = BSInterpolateType::New();
    interp->SetSplineOrder(interpolator);
    resample->SetInterpolator(interp);
    writer->SetInput(resample->GetOutput());

    break;
  }
  }
  
  // write file
  writer->SetFileName(OImage);
  writer->Update();
}
} // namespace dv
#endif

